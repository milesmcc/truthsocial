# frozen_string_literal: true
require 'csv'

namespace :migrate_images do
  task :account, [:batch_size] => [:environment] do |_t, args|
    batch_size = args[:batch_size] || 500

    ids = Account.where(file_s3_host: nil).where('header_file_name is not null or avatar_file_name is not null').order('id desc').limit(batch_size).pluck(:id)
    Images::AccountMigrationWorker.queue_migrations(ids: ids)
  end

  task :media_attachment, [:batch_size] => [:environment] do |_t, args|
    batch_size = args[:batch_size] || 500

    ids = MediaAttachment.where(file_s3_host: nil).where('file_file_name is not null').order('id desc').limit(batch_size).pluck(:id)
    Images::MediaAttachmentMigrationWorker.queue_migrations(ids: ids)
  end

  task :preview_card, [:batch_size] => [:environment] do |_t, args|
    batch_size = args[:batch_size] || 500

    ids = PreviewCard.where(file_s3_host: nil).where('image_file_name is not null').order('id desc').limit(batch_size).pluck(:id)
    Images::PreviewCardMigrationWorker.queue_migrations(ids: ids)
  end
end

namespace :refresh_acls do
  task :account do
    Account.find_in_batches do |batch|
      Images::AccountAclRefreshWorker.queue_migrations(ids: batch.pluck(:id))
    end
  end

  task :preview_card do
    PreviewCard.find_in_batches do |batch|
      Images::PreviewCardAclRefreshWorker.queue_migrations(ids: batch.pluck(:id))
    end
  end
end
