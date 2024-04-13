# frozen_string_literal: true

class GroupRequestNotifyWorker
  include Sidekiq::Worker

  def perform(group_id, request_id)
    @group = Group.find(group_id)
    membership_request = GroupMembershipRequest.find(request_id)

    approvers = load_approvers
    
    approvers.find_each do |member|
      NotifyService.new.call(member, :group_request, membership_request)
    end
  rescue ActiveRecord::RecordNotFound
    true
  end

  private

  def load_approvers
    Account
      .joins(:group_memberships)
      .where(group_memberships: { role: [:admin, :owner], group_id: @group.id })
  end
end
