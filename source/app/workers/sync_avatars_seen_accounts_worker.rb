# frozen_string_literal: true

class SyncAvatarsSeenAccountsWorker
  include Sidekiq::Worker
  def perform(account_id, target_account_id)
    seen_redis_key = "avatars_carousel_seen_accounts:#{account_id}"

    Redis.current.hset(seen_redis_key, target_account_id, Time.now.to_i)
    Redis.current.expire(seen_redis_key, 1.month.seconds)
  end
end