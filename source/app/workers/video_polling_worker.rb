# frozen_string_literal: true

class VideoPollingWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', retry: 15

  def perform(status_id, video_id, url = nil, attempts = 0)
    VideoEncodingStatusService.new.call(status_id, video_id, url, attempts)
  rescue ActiveRecord::RecordNotFound
    true
  end
end
