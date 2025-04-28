# frozen_string_literal: true

class Images::PreviewCardMigrationWorker
  include ImageMigration

  def perform(preview_card_id)
    preview_card = PreviewCard.find_by(id: preview_card_id)
    return if preview_card.nil? || preview_card.file_s3_host || !preview_card.image.file?

    migrate_image(preview_card, :image)
    preview_card.update!(file_s3_host: Paperclip::Attachment.default_options[:s3_host_name])
  end
end
