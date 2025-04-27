# frozen_string_literal: true

class InvalidateDescendantsCacheWorker
  include Sidekiq::Worker
  include Redisable

  def perform(conversation_id)
    redis.del("descendants:#{conversation_id}")
  end
end
