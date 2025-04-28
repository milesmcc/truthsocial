# frozen_string_literal: true

class JoinGroupService < BaseService
  include Redisable
  include DomainControlHelper

  # @param [Account] account Account from which to join
  # @param [Group] group to join
  # @param [Hash] options Options for direct join
  def call(account, group, options = {})
    @account = account
    @group   = group
    @options = options

    raise ActiveRecord::RecordNotFound if joining_not_possible?
    raise Mastodon::NotPermittedError  if joining_not_allowed?

    if (membership = member)
      membership.update(notify: @options[:notify]) unless @options[:notify].nil?
      membership
    else
      raise Mastodon::ValidationError, I18n.t('groups.errors.group_membership_limit') if GroupMembershipValidationService.new(@account).reached_membership_threshold?

      if @group.locked? || @account.silenced? || @group.members_only?
        request_join!
      else
        membership = direct_join!
        invalidate_carousel_cache
        membership
      end
    end
  end

  private

  def member
    @group.memberships.find_by(account_id: @account.id)
  end

  def joining_not_possible?
    @group.nil?
  end

  def joining_not_allowed?
    @group.blocking?(@account) || !@group.discoverable?
  end

  def request_join!
    membership_request = @group.membership_requests.create!(account: @account)
    GroupRequestNotifyWorker.perform_async(@group.id, membership_request.id)
    membership_request
  end

  def direct_join!
    @group.memberships.create!(account: @account)
  end

  def invalidate_carousel_cache
    redis.del("groups_carousel_list_#{@account.id}")
  end
end
