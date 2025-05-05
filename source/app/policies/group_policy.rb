# frozen_string_literal: true

class GroupPolicy < ApplicationPolicy
  def update?
    group_owner?
  end

  def show_group_statuses?
    record.everyone? || member?
  end

  def destroy?
    group_owner?
  end

  def post?
    member?
  end

  def manage_requests?
    group_staff?
  end

  def delete_posts?
    group_staff?
  end

  def manage_blocks?
    group_staff?
  end

  def show?
    private_group? ? member? : true
  end

  private

  def member?
    record.members.where(id: current_account&.id).exists?
  end

  def group_owner?
    record.memberships.where(account_id: current_account&.id, role: :owner).exists?
  end

  def group_staff?
    record.memberships.where(account_id: current_account&.id, role: [:admin, :owner]).exists?
  end

  def private_group?
    record.members_only?
  end
end
