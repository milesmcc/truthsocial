# frozen_string_literal: true

class REST::GroupRelationshipSerializer < Panko::Serializer
  attributes :id, :member, :requested, :role, :blocked_by, :notifying, :pending_requests, :muting

  def id
    object.id.to_s
  end

  def member
    context[:relationships].member[object.id] ? true : false
  end

  def requested
    context[:relationships].requested[object.id] ? true : false
  end

  def role
    context[:relationships].member[object.id] ? context[:relationships].member[object.id][:role] : nil
  end

  def blocked_by
    context[:relationships].banned[object.id] ? true : false
  end

  def notifying
    context[:relationships].member[object.id] ? context[:relationships].member[object.id][:notify] : nil
  end

  def pending_requests
    group_staff = %w(owner admin).include?(context[:relationships].member[object.id]&.dig(:role))
    if group_staff
      return object.membership_requests.present?
    end

    false
  end

  def muting
    context[:relationships].muting[object.id] ? true : false
  end
end
