# frozen_string_literal: true

class InvalidateGroupRelationshipCacheWorker
  include Sidekiq::Worker
  include Redisable

  def perform(account_id, group_id)
    Rails.cache.delete("group_relationship:#{account_id}:#{group_id}")
  end
end