# frozen_string_literal: true

class GroupFeed
  # @params [Group] group
  # @param [Account] account
  # @param [Hash] options
  def initialize(group, account, options = {})
    @group = group
    @account = account
    @options = options

    get_role
  end

  # @param [Integer] limit
  # @param [Integer] max_id
  # @param [Integer] since_id
  # @param [Integer] min_id
  # @return [Array<Status>]
  def get(limit, max_id = nil, since_id = nil, min_id = nil)
    scope = group_scope
    scope.merge!(pinned_only_scope) if pinned_only?
    scope.merge!(account_filters_scope) if account? && @role == 'user'
    scope.merge!(media_only_scope) if media_only?
    scope.merge!(unauthenticated_scope) if unauthenticated?
    scope.cache_ids.to_a_paginated_by_id(limit, max_id: max_id, since_id: since_id, min_id: min_id)
  end

  private

  attr_reader :group, :account, :options

  def account?
    account.present?
  end

  def media_only?
    options[:only_media]
  end

  def pinned_only?
    options[:only_pinned]
  end

  def unauthenticated?
    options[:unauthenticated]
  end

  def group_scope
    scope = Status
            .without_reblogs
            .where(group_id: @group.id, reply: false, quote_id: nil)
            .joins(:account)
            .merge(Account.without_suspended.without_silenced.excluded_by_group_account_block(@group.id))

    scope.merge!(Status.where.not(visibility: 'self').or(Status.where(account_id: @account.id))) if @account
    scope
  end

  def account_filters_scope
    Status.not_excluded_by_account(account).tap do |scope|
      scope.merge!(Status.not_domain_blocked_by_account(account))
    end
  end

  def media_only_scope
    Status.joins(:media_attachments).group(:id)
  end

  def pinned_only_scope
    Status.joins(:status_pins).merge!(StatusPin.group_pins)
  end

  def unauthenticated_scope
    Account.joins(:user).where('users.unauth_visibility': true)
  end

  def get_role
    @role = 'user'
    return unless account?
    membership = GroupMembership.find_by(group_id: @group.id, account_id: @account.id)

    if membership
      @role = membership[:role]
    end
  end
end
