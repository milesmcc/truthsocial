class SyncGroupsSeenWorker
  include Sidekiq::Worker
  def perform(account_id, target_group_id)
    seen_redis_key = "groups_carousel_seen_accounts:#{account_id}"

    Redis.current.hset(seen_redis_key, target_group_id, Time.now.to_i)
    Redis.current.expire(seen_redis_key, 1.month.seconds)
  end
end
