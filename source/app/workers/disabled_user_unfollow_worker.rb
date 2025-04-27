# frozen_string_literal: true

class DisabledUserUnfollowWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', lock: :until_executed

  def perform(account_id)
    # Need to unscope Account search since Account is likely suspended at this point
    DisabledUserUnfollowService.new.call(Account.find(account_id))
  rescue ActiveRecord::RecordNotFound
    true
  end
end
