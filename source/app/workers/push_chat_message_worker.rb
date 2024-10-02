class PushChatMessageWorker
  include Sidekiq::Worker
  include Redisable
  include SecondaryDatacenters

  def perform(chat_id, type, account_id, message_id = nil, first_time = true)
    chat_account_ids = ChatMember.where(chat_id: chat_id).pluck(:account_id)

    case type
    when 'delete'
      event = 'chat_message.deleted'
      custom_payload = { chat_id: chat_id.to_s, deleted_message_id: message_id.to_s }
    when 'read'
      event = 'chat_message.read'
    when 'reaction'
      event = 'chat_message.reaction'
    else
      event = 'chat_message.created'
    end

    chat_account_ids.each do |chat_account_id|
      timeline_id = "timeline:#{chat_account_id}"
      chat = Chat.where(chat_members: { account_id: chat_account_id, active: true }).account_belongs_to.find_by(chat_id: chat_id)

      next unless chat

      if type == 'reaction'
        begin
          custom_payload = ChatMessage.find_message(chat_account_id, chat_id, message_id)
        rescue ActiveRecord::StatementInvalid
          Rails.logger.info('Chat message reaction lookup error:  message ID does not exist')
          next
        end
      end

      other_account_id = chat_account_ids.find { |id| id != chat_account_id } if type == 'read'
      payload = ActiveModelSerializers::SerializableResource.new(chat, serializer: REST::ChatSerializer, account_id: other_account_id || account_id)
      redis.publish(timeline_id, Oj.dump(event: event, payload: custom_payload || payload, queued_at: (Time.now.to_f * 1000.0).to_i))
    end

    return unless first_time

    perform_in_secondary_datacenters(chat_id, type, account_id, message_id, false)
  end
end
