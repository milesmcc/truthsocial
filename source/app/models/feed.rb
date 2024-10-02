# frozen_string_literal: true

class Feed
  include Redisable

  def initialize(type, account)
    @type = type
    @account = account
    @whale_following = whale_following
  end

  def get(limit, max_id = nil, since_id = nil, min_id = nil)
    @limit    = limit.to_i
    @max_id   = max_id.to_i if max_id.present?
    @since_id = since_id.to_i if since_id.present?
    @min_id   = min_id.to_i if min_id.present?
    @fanout_key = feed_key(@type, @account.id)

    status_ids = !@whale_following.empty? && @type == :home ? get_with_whales : get_fanout_only

    Status.
      where(id: status_ids).
      where.not(visibility: "self").
      or(Status.where(id: status_ids).where(account_id: @account.id)).
      cache_ids
  end

  def clear!
    key_to_clear = feed_key(@type, @account.id)
    redis_timelines.del(key_to_clear)
  end

  protected

  def get_fanout_only
    @max_id = '+inf' if @max_id.blank?
    if @min_id.blank?
      @since_id = '-inf' if @since_id.blank?
      FeedManager.instance.status_ids_to_plain_numbers(redis_timelines.zrevrangebyscore(@fanout_key, "(#{@max_id}", "(#{@since_id}", limit: [0, @limit], with_scores: true).map(&:first)).map(&:to_i)
    else
      FeedManager.instance.status_ids_to_plain_numbers(redis_timelines.zrangebyscore(@fanout_key, "(#{@min_id}", "(#{@max_id}", limit: [0, @limit], with_scores: true).map(&:first)).map(&:to_i)
    end
  end

  def get_with_whales
    feed_ids = fanout_and_whales_statuses
    return [] if feed_ids.empty?

    feed_ids = feed_ids.uniq.sort { |a, b| b <=> a }

    if @min_id.blank?
      max_id = @max_id.presence || feed_ids.first
      start_index = feed_ids.find_index(max_id)

      if start_index.nil? # the status has been deleted in the meantime
        filtered_ids = feed_ids.find_all { |n| n < max_id }
        return filtered_ids.first(@limit)
      end

      start_index += 1 if @max_id
      feed_ids[start_index, @limit]
    else
      [] # TODO: if we need to use a reverse pagination
    end
  end

  private

  def fanout_and_whales_statuses
    subsets = redis_timelines.pipelined do |pipeline|
      pipeline.zrange(@fanout_key, '0', '-1')
      @whale_following.each do |account_id|
        pipeline.zrange(feed_key(:whale, account_id), '0', '-1')
      end
    end
    FeedManager.instance.status_ids_to_plain_numbers(subsets.flatten).map(&:to_i)
  end

  def whale_following
    return [] if @type != :home

    cache_key = "whale:following:#{@account.id}"
    if (cached_following = get_following_from_cache(cache_key))
      cached_following
    else
      ids =  @account.whale_following.ids
      redis.set(cache_key, ids.to_json)
      redis.expire(cache_key, 24.hour.seconds)
      ids
    end
  end


  def get_following_from_cache(key)
    cached_following_raw = redis.get(key)
    return if cached_following_raw.nil?

    begin
      parsed = JSON.parse(cached_following_raw)
      parsed.is_a?(Array) ? parsed : false
    rescue JSON::ParserError
      false
    end
  end

  def feed_key(type, account_id)
    FeedManager.instance.key(type, account_id)
  end
end
