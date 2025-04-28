# frozen_string_literal: true

class InvalidateFollowCacheWorker
  include Sidekiq::Worker
  include Redisable

  def perform(source_account_id, target_account_id, whale)
    Rails.cache.delete("relationship/#{source_account_id}/#{target_account_id}")
    Rails.cache.delete("relationship/#{target_account_id}/#{source_account_id}")
    redis.del("whale:following:#{source_account_id}") if whale
  end
end
