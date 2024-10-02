# frozen_string_literal: true

class Images::AccountMigrationWorker
  include ImageMigration

  def perform(account_id)
    account = Account.find_by(id: account_id)
    return if account.nil? || account.file_s3_host || (!account.avatar.file? && !account.header.file?)

    %i(avatar header).each do |attribute|
      migrate_image(account, attribute)
    end
    account.update!(file_s3_host: Paperclip::Attachment.default_options[:s3_host_name])
  end
end
