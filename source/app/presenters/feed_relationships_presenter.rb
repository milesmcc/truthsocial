# frozen_string_literal: true

class FeedRelationshipsPresenter
  include Redisable

  attr_reader :account_feeds, :seen_feeds

  def initialize(feeds, current_account)
    @account_feeds = Feeds::Feed.account_feeds_map(feeds.map(&:id), current_account)
    @seen_feeds = set_seen_feeds(feeds, current_account)
  end

  def set_seen_feeds(feeds, current_account)
    seen = {}

    feeds.map do |feed|
      feed_key = case feed.feed_type
                 when 'for_you'
                   "feed:rec:#{current_account.id}"
                 when 'following'
                   "feed:home:#{current_account.id}"
                 when 'groups'
                   "feed:group:#{current_account.id}"
                 else
                   "feed:custom:#{feed.id}"
                 end

      redis_result = redis.zrange(feed_key, -1, -1)
      latest_status_id = redis_result[0].to_i
      status_time = (latest_status_id >> 16) / 1000
      time = Time.zone.at(status_time)
      seen_feeds = redis.hgetall("seen_feeds:#{current_account.id}")
      seen_time = Time.zone.at(seen_feeds[feed.id.to_s].to_i)
      seen.merge!({ feed.id => seen_time > time })
    end

    seen
  end
end
