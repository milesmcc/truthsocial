# frozen_string_literal: true

class VideoPreviewWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', retry: 5

  def perform(media_attachment_id, url)
    VideoPreviewService.new.call(MediaAttachment.find(media_attachment_id), url)
  rescue ActiveRecord::RecordNotFound
    true
  end
end
