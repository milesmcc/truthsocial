# frozen_string_literal: true

class UnmergeWorker
  include Sidekiq::Worker
  include SecondaryDatacenters

  sidekiq_options queue: 'pull'

  def perform(from_account_id, into_account_id, first_time = true)
    FeedManager.instance.unmerge_from_home(Account.find(from_account_id), Account.find(into_account_id))
    return unless first_time

    perform_in_secondary_datacenters(from_account_id, into_account_id, false)    
  rescue ActiveRecord::RecordNotFound
    true
  end
end
