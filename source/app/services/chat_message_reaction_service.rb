# frozen_string_literal: true

class ChatMessageReactionService
  attr_reader :emoji, :account_id, :message

  def initialize(emoji:, account_id:, message:)
    @emoji = emoji
    @account_id = account_id
    @message = message
  end

  def create
    chat_message = ChatMessageReaction.create!(account_id, message['id'], emoji)
    publish_reaction_event
    chat_message
  rescue StandardError => e
    Rails.logger.error "ChatMessageReaction error: #{e.inspect}"
    raise_unprocessable_entity('Failed to add reaction')
  end

  def destroy
    ChatMessageReaction.destroy!(account_id, message['id'], emoji)
    publish_reaction_event
  rescue StandardError => e
    Rails.logger.error "ChatMessageReaction error: #{e.inspect}"
    raise_unprocessable_entity('Failed to remove reaction')
  end

  private

  def raise_unprocessable_entity(message)
    raise Mastodon::UnprocessableEntityError, message
  end

  def publish_reaction_event
    PushChatMessageWorker.perform_async(message['chat_id'], 'reaction', account_id, message['id'])
  end
end
