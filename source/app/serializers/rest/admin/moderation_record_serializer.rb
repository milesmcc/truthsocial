# frozen_string_literal: true

class REST::Admin::ModerationRecordSerializer < ActiveModel::Serializer
  attributes :id, :status_id, :media_attachment_id, :analysis, :created_at, :updated_at

  def id
    object.id.to_s
  end
end
