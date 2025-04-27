# frozen_string_literal: true

class InvalidateAdsAccountsWorker
  include Sidekiq::Worker
  include Redisable

  sidekiq_options queue: 'pull', lock: :until_executed

  def perform(account_id)
    account = Account.find(account_id)
    OauthAccessToken.where(resource_owner_id: account.user.id, scopes: 'ads').pluck(:token).each do |token|
      redis.del("ads:account:cache:#{token}")
      InvalidateSecondaryCacheService.new.call("InvalidateAdsAccountsCacheWorker", token)
    end
  end
end
