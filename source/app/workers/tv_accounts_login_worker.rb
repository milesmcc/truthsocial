# frozen_string_literal: true

class TvAccountsLoginWorker
  include Sidekiq::Worker

  TV_PASSWORD_SALT = ENV.fetch('TV_PASSWORD_SALT', '')

  sidekiq_options retry: 5

  def perform(account_id, doorkeeper_token_id)
    return if TvDeviceSession.find_by(oauth_access_token_id: doorkeeper_token_id).present?

    tv_account = TvAccount.find_by(account_id: account_id)

    raise Tv::MissingAccountError if tv_account.nil?

    subscriber_id = tv_account.account_uuid
    password = Digest::SHA2.new(256).hexdigest("#{account_id}#{TV_PASSWORD_SALT}")

    session_id = PTv::Client::AccountActions.new.login(subscriber_id, password)

    raise Tv::LoginError, account_id if session_id.nil?

    TvDeviceSession.upsert(
      oauth_access_token_id: doorkeeper_token_id,
      tv_session_id: session_id
    )
  end
end
