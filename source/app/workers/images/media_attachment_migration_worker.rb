# frozen_string_literal: true

class Images::MediaAttachmentMigrationWorker
  include ImageMigration

  def perform(media_attachment_id)
    media_attachment = MediaAttachment.find_by(id: media_attachment_id)
    return if media_attachment.nil? || media_attachment.file_s3_host

    migrate_image(media_attachment, :file)
    media_attachment.update!(file_s3_host: Paperclip::Attachment.default_options[:s3_host_name])
  end
end
