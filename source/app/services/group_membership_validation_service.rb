# frozen_string_literal: true

class GroupMembershipValidationService
  def initialize(account)
    @admin = account.user.admin?
    @memberships = GroupMembership.where(account_id: account.id)
  end

  def reached_group_creation_threshold?
    return false if admin

    memberships.where(role: :owner).size >= ENV.fetch('MAX_GROUP_CREATIONS_ALLOWED', 10).to_i
  end

  def reached_membership_threshold?
    return false if admin

    memberships.joins(:group).merge(Group.kept).size >= ENV.fetch('MAX_GROUP_MEMBERSHIPS_ALLOWED', 50).to_i
  end

  private

  attr_reader :admin, :memberships
end
