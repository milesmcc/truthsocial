# frozen_string_literal: true

module Redisable
  extend ActiveSupport::Concern

  private

  def redis
    Redis.current
  end

  def redis_timelines
    @redis_timelines ||= Redis.new(REDIS_TIMELINES_PARAMS)
  end

  def redis_sidekiq
    @redis_sidekiq ||= Redis.new(REDIS_SIDEKIQ_PARAMS)
  end

end
