# frozen_string_literal: true

class SyncSeenFeedsWorker
  include Sidekiq::Worker
  def perform(account_id, feed_id)
    key = "seen_feeds:#{account_id}"

    Redis.current.hset(key, feed_id, Time.now.utc.to_i)
    Redis.current.expire(key, 1.month.seconds)
  end
end
