# frozen_string_literal: true

class RateLimiter
  include Redisable

  FAMILIES = {
    follows: {
      limit: 250,
      period: 24.hours.freeze,
    }.freeze,

    statuses: {
      limit: 300,
      period: 3.hours.freeze,
    }.freeze,

    reports: {
      limit: 400,
      period: 24.hours.freeze,
    }.freeze,
  }.freeze

  def initialize(by, options = {})
    @by     = by
    @family = options[:family]
    @limit  = self.class::FAMILIES[@family][:limit]
    @period = self.class::FAMILIES[@family][:period].to_i
  end

  def record!
    count = redis.get(key)

    if count.nil?
      redis.set(key, 0)
      count = 0
      redis.expire(key, (@period - (last_epoch_time % @period) + 1).to_i)
    end

    raise error, "Rate limit hit by #{self.class.name} #{@family}" if count.to_i >= @limit && ENV['SKIP_IP_RATE_LIMITING'] != 'true'

    redis.incr(key)
  end

  def rollback!
    redis.decr(key)
  end

  def error
    Mastodon::RateLimitExceededError
  end

  def to_headers(now = Time.now.utc)
    {
      'X-RateLimit-Limit' => @limit.to_s,
      'X-RateLimit-Remaining' => (@limit - (redis.get(key) || 0).to_i).to_s,
      'X-RateLimit-Reset' => (now + (@period - now.to_i % @period)).iso8601(6),
    }
  end

  private

  def key
    @key ||= "rate_limit:#{@by.id}:#{@family}:#{(last_epoch_time / @period).to_i}"
  end

  def last_epoch_time
    @last_epoch_time ||= Time.now.to_i
  end
end
