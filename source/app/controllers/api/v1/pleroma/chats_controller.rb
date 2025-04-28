# frozen_string_literal: true
class Api::V1::Pleroma::ChatsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }, only: [:index, :show, :get_by_account_id, :sync]
  before_action -> { doorkeeper_authorize! :write }, only: [:by_account_id, :mark_read, :accept, :update, :destroy]
  before_action :require_user!
  before_action :set_account
  before_action :set_chat, only: [:show, :accept, :mark_read, :update, :destroy]
  before_action :set_chat_member, only: [:accept, :mark_read, :destroy]
  before_action :set_chat_message, only: :mark_read
  before_action :set_recipient, only: [:by_account_id, :get_by_account_id]
  after_action :insert_pagination_headers, unless: -> { @chats.empty? }, only: [:index, :sync]
  after_action :set_unread_messages_header, unless: -> { @chats.empty? }, only: [:index, :sync]

  DEFAULT_CHATS_LIMIT = 20

  def index
    @chats = load_chats
    render json: @chats, each_serializer: REST::ChatSerializer
  end

  def show
    render json: @chat, serializer: REST::ChatSerializer
  end

  def by_account_id
    chat = ChatService.new(account: @account, recipient: @recipient).call
    render json: chat, serializer: REST::ChatSerializer, recipient: @recipient
  end

  def get_by_account_id
    chat = Chat.with_member
      .where(chat_members: { account_id: @account.id, active: true })
      .find_by!(members: [@recipient.id, @account.id].sort)

    render json: chat, serializer: REST::ChatSerializer, recipient: @recipient
  end

  def mark_read
    @chat_member.update(latest_read_message_created_at: @chat_message['created_at'])
    set_chat
    push_read_receipt
    render json: @chat, serializer: REST::ChatSerializer
  end

  def accept
    if @chat.owner_account_id != @account.id
      @chat_member.update(accepted: true)
      @chat.accepted = true
      render json: @chat, serializer: REST::ChatSerializer
    else
      render json: { error: I18n.t('chats.errors.creator_started') }, status: 422
    end
  end

  def update
    if @chat.channel? && @chat.owner_account_id != @account.id
      render json: @chat, serializer: REST::ChatSerializer
      return
    end

    message_expiration = create_expiration_duration(update_params[:message_expiration].to_i)
    @chat.update!(message_expiration: message_expiration)
    @chat.message_expiration = update_params[:message_expiration].to_i
    render json: @chat, serializer: REST::ChatSerializer
  end

  def destroy
    chat_obj = Chat.account_belongs_to.find_by(chat_id: @chat.chat_id)
    @chat_member.update(active: false)
    # Postgres 🪄: after the last member of a chat is inactive, the database moves the chat record to deleted_chats
    render json: chat_obj, serializer: REST::ChatSerializer, last_message: {}
  end

  def sync
    @chats = ChatMemberRemoval
      .where(account_id: @account.id)
      .order(removed_at: :asc)
      .paginate_by_time(
        limit_param(DEFAULT_CHATS_LIMIT),
        params[:to],
        params[:from]
      )

    render json: @chats, each_serializer: REST::ChatMemberRemovalSerializer
  end

  private

  def create_expiration_duration(interval)
    ActiveSupport::Duration.build(interval).seconds
  end

  def load_chats
    Chat.account_belongs_to
      .where(chat_members: { account_id: @account.id })
      .has_account_like(chats_params[:search])
      .ordered
      .paginate_by_ordered_max_id(
        limit_param(DEFAULT_CHATS_LIMIT),
        params[:max_id],
        params[:since_id],
        @account.id
      )
  end

  def set_account
    @account = current_user.account
  end

  def set_recipient
    @recipient = Account.find(params[:account_id])
  end

  def set_chat
    @chat = Chat.account_belongs_to
      .where(chat_members: { account_id: @account.id })
      .find_by!(chat_id: chat_id)
  end

  def chat_id
    params[:chat_id] || params[:id]
  end

  def set_chat_member
    @chat_member = ChatMember.find([chat_id, @account.id])
  end

  def set_chat_message
    chat_message = ChatMessage.find_message(@account.id, chat_id, mark_read_params)
    @chat_message = JSON.parse(chat_message)
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.info "Chat Message error: #{e.inspect}"
    raise ActiveRecord::RecordNotFound
  end

  def insert_pagination_headers
    set_pagination_headers(next_path, prev_path)
  end

  def next_path
    if action_name == "sync"
      pagination_path pagination_params(from: @chats.last.removed_at.to_i)
    elsif @chats.size == limit_param(DEFAULT_CHATS_LIMIT)
      pagination_path pagination_params(max_id: @chats.last.id, search: chats_params[:search])
    end
  end

  def prev_path
    unless @chats.empty?
      if action_name == "sync"
        pagination_path pagination_params(to: @chats.first.removed_at.to_i)
      else
        pagination_path pagination_params(since_id: @chats.first.id, search: chats_params[:search])
      end
    end
  end

  def pagination_path(params)
    if action_name == "sync"
      api_v1_pleroma_chats_sync_url params
    else
      api_v1_pleroma_chats_url params
    end
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end

  def chats_params
    params.permit(:search)
  end

  def mark_read_params
    params.require(:last_read_id)
  end

  def update_params
    params.permit(:message_expiration)
  end

  def set_unread_messages_header
    response.headers['X-Unread-Messages-Count'] = ChatMember.where(account_id: @account.id).sum(:unread_messages_count)
  end

  def push_read_receipt
    return if @chat.channel?
    return unless Redis.current.exists?("subscribed:timeline:#{@chat.account_id}")

    PushChatMessageWorker.perform_async(@chat.chat_id, 'read', @chat.account_id)
  end
end
