# frozen_string_literal: true

class UploadVideoChatWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', lock: :until_executed

  def perform(media_attachment_id)
    UploadVideoChatService.new.call(MediaAttachment.find(media_attachment_id))
  rescue ActiveRecord::RecordNotFound
    true
  end
end
