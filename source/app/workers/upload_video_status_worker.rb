# frozen_string_literal: true

class UploadVideoStatusWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', lock: :until_executed

  def perform(media_attachment_id, status_id)
    UploadVideoStatusService.new.call(
      MediaAttachment.find(media_attachment_id),
      Status.find(status_id),
    )
  rescue ActiveRecord::RecordNotFound
    true
  end
end
