# frozen_string_literal: true

class InvalidateAdsAccountsCacheWorker
  include Sidekiq::Worker
  include Redisable
  
  def perform(token)
    redis.del("ads:account:cache:#{token}");
  end
end
