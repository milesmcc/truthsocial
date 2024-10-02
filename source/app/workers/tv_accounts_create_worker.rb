# frozen_string_literal: true

class TvAccountsCreateWorker
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed

  TV_PASSWORD_SALT = ENV.fetch('TV_PASSWORD_SALT', '')

  sidekiq_options retry: 5

  def perform(account_id, doorkeeper_token_id)
    @account_id = account_id
    @doorkeeper_token_id = doorkeeper_token_id

    tv_account = TvAccount.find_by(account_id: @account_id)
    return if tv_account&.p_profile_id

    @subscriber_id = tv_account&.account_uuid

    RedisLock.acquire(lock_options) do |lock|
      if lock.acquired?
        sign_up unless @subscriber_id
        login
        set_profile
      else
        raise Mastodon::RaceConditionError
      end
    end
  end

  private

  def sign_up
    @subscriber_id = SecureRandom.uuid
    response = PTv::Provider::CreateSubscriberService.new.call(@subscriber_id, password)
    raise Tv::SignUpError, @account_id unless response.code == '200'

    TvAccount.create!(account_id: @account_id, account_uuid: @subscriber_id, p_profile_id: nil)
  end

  def login
    @session_id = PTv::Client::AccountActions.new.login(@subscriber_id, password)
    raise Tv::LoginError, @account_id if @session_id.nil?

    TvDeviceSession.upsert(
      oauth_access_token_id: @doorkeeper_token_id,
      tv_session_id: @session_id
    )
  end

  def set_profile
    profiles = PTv::Client::AccountActions.new.profiles_list(@session_id)
    raise Tv::GetProfilesError, @session_id if profiles.nil? || profiles[0].nil? || !profiles[0].key?('guid')
    tv_profile_id = profiles[0]['guid']
    TvAccount.where(account_id: @account_id).first.update(p_profile_id: tv_profile_id)
  end

  def password
    Digest::SHA2.new(256).hexdigest("#{@account_id}#{TV_PASSWORD_SALT}")
  end

  def lock_options
    { redis: Redis.current, key: "tv_accounts_create:#{@account_id}", autorelease: 1.minute.seconds }
  end
end
