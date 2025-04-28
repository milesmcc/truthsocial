# frozen_string_literal: true

class GroupFilter
  KEYS = %i(
    order
    by_member
  ).freeze

  attr_reader :params

  def initialize(params)
    @params = params
  end

  def results
    scope = Group.includes(:group_stat, :tags).reorder(nil)

    params.each do |key, value|
      scope.merge!(scope_for(key, value)) if value.present?
    end

    scope
  end

  private

  def scope_for(key, value)
    case key.to_s
    when 'by_member'
      Group.joins(:memberships).merge(GroupMembership.where(account_id: value.to_s))
    when 'by_member_role'
      Group.joins(:memberships).merge(GroupMembership.where(role: value))
    when 'order'
      order_scope(value)
    else
      raise "Unknown filter: #{key}"
    end
  end

  def order_scope(value)
    case value.to_s
    when 'active'
      Group.left_joins(:group_stat).order(Arel.sql('coalesce(group_stats.last_status_at, to_timestamp(0)) desc, groups.id desc'))
    when 'recent'
      Group.recent
    else
      raise "Unknown order: #{value}"
    end
  end
end
