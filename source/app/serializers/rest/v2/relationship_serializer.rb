# frozen_string_literal: true

class REST::V2::RelationshipSerializer < Panko::Serializer
  attributes :id, :following, :showing_reblogs, :notifying, :followed_by,
             :blocking, :blocked_by, :muting, :muting_notifications, :requested,
             :domain_blocking, :endorsed, :note

  def id
    object.id.to_s
  end

  def following
    context[:relationships].following[object.id] ? true : false
  end

  def notifying
    (context[:relationships].following[object.id] || {})[:notify] || false
  end

  def followed_by
    context[:relationships].followed_by[object.id] || false
  end

  def blocking
    context[:relationships].blocking[object.id] || false
  end

  def blocked_by
    context[:relationships].blocked_by[object.id] || false
  end

  def muting
    context[:relationships].muting[object.id] ? true : false
  end

  def muting_notifications
    (context[:relationships].muting[object.id] || {})[:notifications] || false
  end

  def note
    (context[:relationships].account_note[object.id] || {})[:comment] || ''
  end

  def requested
    false
  end

  def domain_blocking
    false
  end

  def endorsed
    false
  end

  def showing_reblogs
    false
  end
end
