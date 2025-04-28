# frozen_string_literal: true

class Images::AccountAclRefreshWorker
  include ImageMigration

  def perform(account_id)
    account = Account.find_by(id: account_id)
    return if account.nil?

    refresh_acls(account)
  end

  private

  def refresh_acls(account)
    acl = account.suspended? ? 'private' : 'public-read'

    account.media_attachments.find_each do |media_attachment|
      refresh_acl(object: media_attachment, names: MediaAttachment.attachment_definitions.keys, acl: acl)
    end

    refresh_acl(object: account, names: Account.attachment_definitions.keys, acl: acl)
  end
end
