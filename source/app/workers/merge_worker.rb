# frozen_string_literal: true

class MergeWorker
  include Sidekiq::Worker
  include SecondaryDatacenters

  sidekiq_options retry: 5

  def perform(from_account_id, into_account_id, first_time = true)
    FeedManager.instance.merge_into_home(Account.find(from_account_id), Account.find(into_account_id))
    return unless first_time

    perform_in_secondary_datacenters(from_account_id, into_account_id, false)
  rescue ActiveRecord::RecordNotFound
    true
  ensure
    Redis.current.del("account:#{into_account_id}:regeneration")
  end
end
