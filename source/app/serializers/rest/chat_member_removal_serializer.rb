# frozen_string_literal: true

class REST::ChatMemberRemovalSerializer < ActiveModel::Serializer
  attributes :chat_id, :removed_at

  def chat_id
    object.chat_id.to_s
  end
end