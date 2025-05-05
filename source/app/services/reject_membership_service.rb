# frozen_string_literal: true

class RejectMembershipService < BaseService
  include Payloadable

  def call(membership_request)
    membership_request.reject!
    membership_request
  end
end
