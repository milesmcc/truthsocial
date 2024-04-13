# frozen_string_literal: true

class Images::PreviewCardAclRefreshWorker
  include ImageMigration

  def perform(preview_card_id)
    preview_card = PreviewCard.find_by(id: preview_card_id)
    return if preview_card.nil?

    refresh_acls(preview_card)
  end

  private

  def refresh_acls(preview_card)
    refresh_acl(object: preview_card, names: PreviewCard.attachment_definitions.keys, acl: 'public-read')
  end
end
