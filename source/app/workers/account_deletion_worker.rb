# frozen_string_literal: true

class AccountDeletionWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', lock: :until_executed

  def perform(account_id, deleted_by_id, options = {})
    reserve_username = options.with_indifferent_access.fetch(:reserve_username, true)
    skip_activitypub = options.with_indifferent_access.fetch(:skip_activitypub, false)
    deletion_type = options.with_indifferent_access.fetch(:deletion_type, 'unknown')
    DeleteAccountService.new.call(
      Account.find(account_id),
      deleted_by_id,
      deletion_type: deletion_type,
      reserve_email: false,
      reserve_username: reserve_username,
      skip_activitypub: skip_activitypub,
    )
  rescue ActiveRecord::RecordNotFound
    true
  end
end
