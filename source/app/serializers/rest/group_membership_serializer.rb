# frozen_string_literal: true

class REST::GroupMembershipSerializer < Panko::Serializer
  attributes :id,
             :role,
             :account

  def id
    object.id.to_s
  end

  def account
    REST::V2::AccountSerializer.new.serialize(object.account)
  end
end
