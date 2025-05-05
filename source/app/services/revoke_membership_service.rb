# frozen_string_literal: true

class RevokeMembershipService < BaseService

  def call(membership)
    return unless membership.group.local?
    membership.destroy
  end
end
