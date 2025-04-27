# frozen_string_literal: true

class AuthorizeMembershipService < BaseService
  include Payloadable
  include Redisable

  def call(membership_request)
    membership_request.authorize!
    GroupAcceptanceNotifyWorker.perform_async(membership_request.group_id, membership_request.account_id)
    redis.del("groups_carousel_list_#{membership_request.account_id}")
    membership_request
  end
end
