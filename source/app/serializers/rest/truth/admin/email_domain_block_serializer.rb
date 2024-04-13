# frozen_string_literal: true

class REST::Truth::Admin::EmailDomainBlockSerializer < ActiveModel::Serializer
  attributes :id, :domain, :created_at, :updated_at

  def id
    object.id.to_s
  end

  delegate :domain, to: :object

  def created_at
    object.created_at.midnight.as_json
  end

  def updated_at
    object.created_at.midnight.as_json
  end
end
