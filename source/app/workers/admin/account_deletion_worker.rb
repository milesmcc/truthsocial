# frozen_string_literal: true

class Admin::AccountDeletionWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull'

  def perform(account_id, deleted_by_id)
    DeleteAccountService.new.call(
      Account.find(account_id),
      deleted_by_id,
      deletion_type: 'worker_admin_account_deletion',
      reserve_username: true,
      reserve_email: true,
      skip_activitypub: true,
     )
  rescue ActiveRecord::RecordNotFound
    true
  end
end
