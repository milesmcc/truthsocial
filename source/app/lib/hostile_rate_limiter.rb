# frozen_string_literal: true

class HostileRateLimiter < RateLimiter
  include Redisable

  FAMILIES = {
    follows: {
      limit: 0,
      period: 24.hours.freeze,
    }.freeze,

    statuses: {
      limit: 0,
      period: 3.hours.freeze,
    }.freeze,

    reports: {
      limit: 0,
      period: 24.hours.freeze,
    }.freeze,
  }.freeze

  private

  def error
    Mastodon::HostileRateLimitExceededError
  end

  def key
    @key ||= "hostile_rate_limit:#{@by.id}:#{@family}:#{(last_epoch_time / @period).to_i}"
  end
end
