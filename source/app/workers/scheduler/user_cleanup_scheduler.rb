# frozen_string_literal: true

class Scheduler::UserCleanupScheduler
  include Sidekiq::Worker

  sidekiq_options retry: 0

  def perform
    clean_unconfirmed_accounts!
    clean_suspended_accounts!
    # clean_suspended_groups! # Revisit once we have a deletion strategy
  end

  private

  def clean_unconfirmed_accounts!
    User.where('confirmed_at is NULL AND confirmation_sent_at <= ?', 2.days.ago).reorder(nil).find_in_batches do |batch|
      Account.where(id: batch.map(&:account_id)).delete_all
      User.where(id: batch.map(&:id)).delete_all
    end
  end

  def clean_suspended_accounts!
    AccountDeletionRequest.where('created_at <= ?', AccountDeletionRequest::DELAY_TO_DELETION.ago).where(Account.where('account_deletion_requests.account_id = accounts.id and accounts.suspended_at <= ?', AccountDeletionRequest::DELAY_TO_DELETION.ago).arel.exists).reorder(nil).find_each do |deletion_request|
      Admin::AccountDeletionWorker.perform_async(deletion_request.account_id, -99)
    end
  end

  # def clean_suspended_groups!
  #   GroupDeletionRequest.where('created_at <= ?', GroupDeletionRequest::DELAY_TO_DELETION.ago).reorder(nil).find_each do |deletion_request|
  #     Admin::GroupDeletionWorker.perform_async(deletion_request.group_id)
  #   end
  # end
end
