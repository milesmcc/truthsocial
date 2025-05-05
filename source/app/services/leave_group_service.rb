# frozen_string_literal: true

class LeaveGroupService < BaseService
  include Redisable
  include GroupCachable
  # @param [Account] account Where to leave from
  # @param [Group] group Which group to unfollow
  def call(account, group)
    @account = account
    @group   = group

    leave! || undo_join_request!
  end

  private

  def leave!
    membership = GroupMembership.find_by(account: @account, group: @group)

    return unless membership

    raise Mastodon::NotPermittedError if membership.owner_role?

    membership.destroy!
    invalidate_group_caches(@account, @group)
  end

  def undo_join_request!
    membership_request = GroupMembershipRequest.find_by(account: @account, group: @group)

    return unless membership_request

    membership_request.destroy!
  end
end
