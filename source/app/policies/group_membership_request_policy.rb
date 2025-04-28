# frozen_string_literal: true

class GroupMembershipRequestPolicy < ApplicationPolicy
  def index?
    group_staff?
  end

  def accept?
    group_staff?
  end

  def reject?
    group_staff? || requested_user?
  end

  private

  def group_staff?
    record.group.memberships.where(account_id: current_account&.id, role: [:admin, :owner]).exists?
  end

  def requested_user?
    record.account_id == current_account.id
  end
end
