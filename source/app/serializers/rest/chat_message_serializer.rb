# frozen_string_literal: true

class REST::ChatMessageSerializer < ActiveModel::Serializer
  include Redisable

  attributes :account_id, :chat_id, :content, :created_at, :id, :unread, :expiration, :idempotency_key

  def account_id
    object.created_by_account_id.to_s
  end

  def chat_id
    object.chat_id.to_s
  end

  def id
    object.message_id.to_s
  end

  def content
    Formatter.instance.format_chat_message(object.content) if object.content
  end

  def unread
    # the only time we don't pass in a chat object is for showing single messages & creating messages
    if instance_options[:chat]
      # the only time we pass an account_id is from the PushChatMessageWorker
      if instance_options[:account_id]
        return instance_options[:chat].latest_read_message_created_at == object.created_at ? false : true
      end

      return instance_options[:chat].latest_read_message_created_at < object.created_at ? true : false
    end

    false
  end

  def idempotency_key
    instance_options[:idempotency_key]
  end

  def expiration
    return ENV.fetch('MARKETING_MESSAGE_EXPIRATION', 60).to_i if instance_options[:channel]

    object.expiration
  end
end
