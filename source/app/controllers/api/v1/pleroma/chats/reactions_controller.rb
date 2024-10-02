# frozen_string_literal: true
class Api::V1::Pleroma::Chats::ReactionsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }, only: :show
  before_action -> { doorkeeper_authorize! :write }, only: [:create, :destroy]
  before_action :require_user!
  before_action :set_account
  before_action :set_chat_message
  before_action :reject_channel
  before_action :set_reaction, only: [:show]

  def show
    render json: @reaction
  end

  def create
    render json: ChatMessageReactionService.new(emoji: params[:emoji], account_id: @account.id, message: @message).create
  end

  def destroy
    ChatMessageReactionService.new(emoji: params[:emoji], account_id: @account.id, message: @message).destroy
  end

  private

  def set_account
    @account = current_user.account
  end

  def set_chat_message
    message = ChatMessage.find_message(@account.id, params[:chat_id], params[:message_id])
    @message = JSON.parse(message)
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.info "Chat Message error: #{e.inspect}"
    raise ActiveRecord::RecordNotFound

  end

  def reject_channel
    chat = Chat.find(@message['chat_id'])
    raise Mastodon::UnprocessableEntityError, I18n.t('chats.errors.channel_reaction') if chat.channel?
  end

  def set_reaction
    @reaction = ChatMessageReaction.find(@account.id, @message['id'], params[:emoji])
    raise ActiveRecord::RecordNotFound unless @reaction
  end
end
