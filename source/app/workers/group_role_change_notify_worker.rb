
# frozen_string_literal: true

class GroupRoleChangeNotifyWorker
  include Sidekiq::Worker

  def perform(group_id, account_id, type)
    group = Group.find(group_id)
    account = Account.find(account_id)
    role_change = type == 'promotion' ? :group_promoted : :group_demoted

    NotifyService.new.call(account, role_change, group)
  rescue ActiveRecord::RecordNotFound
    true
  end
end