# frozen_string_literal: true

class REST::ChatSerializer < ActiveModel::Serializer
  attributes :id, :unread, :created_by_account, :last_message, :created_at, :accepted, :account, :message_expiration, :latest_read_message_created_at, :latest_read_message_by_account, :chat_type

  def id
    object.chat_id.to_s
  end

  def created_by_account
    object.owner_account_id.to_s
  end

  def account
    if account_obj
      ActiveModelSerializers::SerializableResource.new(account_obj, serializer: REST::AccountSerializer).as_json
    end
  end

  def account_obj
    return instance_options[:recipient] if instance_options[:recipient]

    if instance_options[:account_id]
      Account.find_by(id: instance_options[:account_id])
    else
      Account.find_by(id: object.other_member_account_ids.first)
    end
  end

  def unread
    object.unread_messages_count
  end

  def last_message
    if instance_options[:last_message]
      return instance_options[:last_message] == {} ? nil : instance_options[:last_message]
    end

    if object.latest_message_id
      message = JSON.parse(ChatMessage.find_message(object.account_id, object.chat_id, object.latest_message_id))
      return message if message['id']
    end
  end


  def latest_read_message_by_account
    return if !last_message || object.chat_type != "direct"

    object.chat_members.map do |member|
      { id: member.account_id.to_s, date: member.latest_read_message_created_at }
    end
  end
end
