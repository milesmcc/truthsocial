# frozen_string_literal: true

class GroupAcceptanceNotifyWorker
  include Sidekiq::Worker

  def perform(group_id, account_id)
    account = Account.find(account_id)
    group = Group.find(group_id)

    NotifyService.new.call(account, :group_approval, group)
  rescue ActiveRecord::RecordNotFound
    true
  end
end
