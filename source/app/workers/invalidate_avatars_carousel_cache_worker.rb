# frozen_string_literal: true

class InvalidateAvatarsCarouselCacheWorker
  include Sidekiq::Worker
  def perform(account_id)
    Redis.current.del("avatars_carousel_list_#{account_id}")
  end
end
