# frozen_string_literal: true

class InvalidateStatusCacheWorker
  include Sidekiq::Worker
  def perform(status_id)
    Rails.cache.delete("statuses/#{status_id}")
  end
end
