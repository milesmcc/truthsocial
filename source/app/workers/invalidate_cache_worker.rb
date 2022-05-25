# frozen_string_literal: true

class InvalidateCacheWorker
  include Sidekiq::Worker

  def perform(key)
    Rails.cache.delete(key)
  end
end
