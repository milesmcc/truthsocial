# frozen_string_literal: true

class RegenerationWorker
  include Sidekiq::Worker
  include SecondaryDatacenters

  sidekiq_options lock: :until_executed

  def perform(account_id, _ = :home, first_time = true)
    account = Account.find(account_id)
    PrecomputeFeedService.new.call(account)
    return unless first_time

    perform_in_secondary_datacenters(account_id, :home, false)
  rescue ActiveRecord::RecordNotFound
    true
  end
end
