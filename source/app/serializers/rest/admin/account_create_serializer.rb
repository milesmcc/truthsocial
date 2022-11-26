# frozen_string_literal: true

class REST::Admin::AccountCreateSerializer < ActiveModel::Serializer
  attributes :id, :verified, :email, :confirmed, :approved

  def id
    object.id.to_s
  end

  def email
    object.user_email
  end

  delegate :verified?, to: :object

  def confirmed
    object.user_confirmed?
  end

  def approved
    object.user_approved?
  end
end
