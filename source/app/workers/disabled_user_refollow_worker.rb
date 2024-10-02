# frozen_string_literal: true

class DisabledUserRefollowWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', lock: :until_executed

  def perform(account_id)
    DisabledUserRefollowService.new.call(Account.find(account_id))
  rescue ActiveRecord::RecordNotFound
    true
  end
end
