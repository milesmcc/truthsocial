# frozen_string_literal: true

module TrackAdImpressionsConcern
  extend ActiveSupport::Concern
  include Redisable

  EXPIRE_AFTER = 7.days.seconds

  def store_impression_response(response_code)
    Redis.current.zincrby(statuses_counter_name, 1, response_code)
    Redis.current.expire(statuses_counter_name, EXPIRE_AFTER)
  end

  def store_failed_impression
    Redis.current.incr(failed_counter_name)
    Redis.current.expire(failed_counter_name, EXPIRE_AFTER)
  end

  private

  def failed_counter_name
    today = Time.now.strftime('%Y-%m-%d')
    "ads-impressions-#{@provider}-fails:#{today}"
  end

  def statuses_counter_name
    today = Time.now.strftime('%Y-%m-%d')
    "ads-impressions-#{@provider}-statuses-codes:#{today}"
  end
end
