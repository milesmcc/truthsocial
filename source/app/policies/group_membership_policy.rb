# frozen_string_literal: true

class GroupMembershipPolicy < ApplicationPolicy
  def revoke?
    group_staff? && rank_from_role(record.role) < rank_from_role(group_role)
  end

  def change_role?
    group_owner? && rank_from_role(record.role) < rank_from_role(group_role)
  end

  private

  def rank_from_role(role)
    %i(user admin owner).index(role.to_sym)
  end

  def group_role
    record.group.memberships.find_by(account_id: current_account&.id)&.role
  end

  def group_owner?
    record.group.memberships.where(account_id: current_account&.id, role: :owner).exists?
  end

  def group_staff?
    record.group.memberships.where(account_id: current_account&.id, role: [:admin, :owner]).exists?
  end
end
