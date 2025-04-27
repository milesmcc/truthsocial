class ChatMessageService < BaseService
  include Redisable

  def initialize(chat_id:, content:, created_by_account_id:, recipient:, silenced:, idempotency:, unfollowed_and_left:, chat_expiration:, media_attachment_ids: [], token:)
    @chat_id = chat_id
    @content = content
    @created_by_account_id = created_by_account_id
    @recipient = recipient
    @silenced = silenced
    @idempotency = idempotency
    @unfollowed_and_left = unfollowed_and_left
    @chat_expiration = chat_expiration
    @media_attachment_ids = media_attachment_ids
    @token = token
  end

  def call
    begin
      message = ChatMessage.create_by_function!({
        account_id: @created_by_account_id,
        token: (@token if @idempotency),
        idempotency_key: @idempotency.presence,
        chat_id: @chat_id,
        content: @content,
        media_attachment_ids: media_attachments,
      })

      ChatMessage.publish_chat_message('create', message)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
      Rails.logger.error "ChatMessage error: #{e.inspect}"
      raise Mastodon::UnprocessableEntityError, I18n.t('chats.errors.message_creation')
    end

    parsed_message = JSON.parse(message)
    chat_message = ChatMessage.find_message(@created_by_account_id, @chat_id, parsed_message['id'])
    decoded = ActiveSupport::JSON.decode(chat_message)
    decoded['created_by_account_id'] = decoded['account_id']
    chat_message_obj = ChatMessage.new(decoded)
  
    NotifyService.new.call(@recipient, :chat, chat_message_obj) unless @silenced || @unfollowed_and_left
    message

  rescue ActiveRecord::RecordNotUnique
    message
  end

  private

  def media_attachments
    return unless @media_attachment_ids

    "{#{@media_attachment_ids.map(&:to_i).join(',')}}"
  end
end
