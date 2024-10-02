# frozen_string_literal: true
class Api::V1::Pleroma::Chats::MessagesController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }, only: [:index, :show, :sync]
  before_action -> { doorkeeper_authorize! :write }, only: [:create, :destroy]
  before_action :require_user!
  before_action :set_account
  before_action :set_chat, only: [:index, :create, :destroy]
  before_action :set_recipient, only: [:create, :destroy]
  before_action :set_chat_message, only: [:destroy, :show]
  before_action :reject_blocked_recipient, only: :create
  before_action :set_silence_status, only: [:create, :destroy]
  before_action :reject_unfollowed_and_left_chat, only: :create
  after_action :insert_pagination_headers, unless: -> { @messages.nil? }, only: :index
  after_action :create_device_verification_message, only: :create

  include Assertable

  DEFAULT_MESSAGES_LIMIT = 20

  def index
    @messages = ChatMessage.load_messages(
      @account.id,
      @chat.chat_id,
      params[:min_id].presence || params[:since_id],
      params[:max_id],
      !params[:min_id].nil?,
      limit_param(DEFAULT_MESSAGES_LIMIT)
    )

    render json: @messages || []
  end

  def create
    @recipient_chat_member.update(active: true) unless @recipient_chat_member.active
    @channel = @chat.channel?

    validate_media!

    if @channel
      @message = serialize_and_publish(chat_message_params[:content], @account.id, @recipient.id)
      serialize_and_publish(I18n.t('chats.marketing_reply'), @recipient.id, @recipient.id)
      render json: message, serializer: REST::ChatMessageSerializer, idempotency_key: request.headers['Idempotency-Key'], channel: @channel
    else
      content = process_links_service.call(chat_message_params[:content], @account.id)

      @message = ChatMessageService.new(
        chat_id: chat_message_params[:chat_id],
        chat_expiration: @chat.message_expiration,
        content: content,
        created_by_account_id: @account.id,
        recipient: @recipient,
        silenced: @silenced,
        idempotency: request.headers['Idempotency-Key'],
        unfollowed_and_left: @unfollowed_and_left,
        media_attachment_ids: @media&.pluck(:id) || [],
        token: doorkeeper_token.token
      ).call

      export_prometheus_metric
      send_videos_to_upload_worker if @media.present?

      render json: @message
    end
  end

  def destroy
    account_id = @account.id
    message = JSON.parse(@message)
    message_id = message['id']

    if message['account_id'].to_i == account_id
      ChatMessage.destroy_message!(account_id, message_id)
      deleted_message = { 'account_id' => account_id, 'chat_id' => @chat.chat_id, 'id' => message_id }
      ChatMessage.publish_chat_message('delete', deleted_message)
    else
      ChatMessageHidden.hide_message(account_id, message_id)
    end

    render json: @message
  end

  def show
    render json: @message
  end

  def sync
    deleted_messages = ChatMessage.deleted_since(@account.id, params[:chat_id], sync_param.to_i)
    id_array = deleted_messages.delete('{}').split(',').map(&:to_i)
    render json: id_array
  end

  private

  def serialize_and_publish(content, account_id, owner_account_id)
    last_message = ChatMessage.new(
      message_id: rand(-1_000_000..-1),
      chat_id: chat_message_params[:chat_id],
      content: content,
      created_by_account_id: account_id,
      created_at: Time.now
    )

    payload = ActiveModelSerializers::SerializableResource.new(@chat, serializer: REST::ChatSerializer, account_id: owner_account_id, last_message: ActiveModelSerializers::SerializableResource.new(last_message, serializer: REST::ChatMessageSerializer, channel: @channel))
    redis.publish("timeline:#{@account.id}", Oj.dump(event: 'chat_message.created', payload: payload, queued_at: (Time.now.to_f * 1000.0).to_i))

    last_message
  end

  def set_account
    @account = current_user.account
  end

  def set_chat
    @chat = Chat.account_belongs_to
                .where(chat_members: { account_id: @account.id })
                .find_by!(chat_id: params[:chat_id])
  end

  def set_recipient
    @recipient = Account.find_by!(id: @chat.other_member_account_ids.first)
    @recipient_chat_member = ChatMember.find([@chat.chat_id, @recipient.id])
  end

  def set_chat_message
    @message = ChatMessage.find_message(@account.id, params[:chat_id], params[:id])
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.info "Chat Message error: #{e.inspect}"
    raise ActiveRecord::RecordNotFound
  end

  def chat_message_params
    params.permit(:chat_id, :content, media_ids: [])
  end

  def insert_pagination_headers
    @messages = JSON.parse(@messages)
    set_pagination_headers(next_path, prev_path)
  end

  def next_path
    if records_continue?
      if params[:min_id]
        api_v1_pleroma_chat_messages_url pagination_params(min_id: pagination_max_id)
      else
        api_v1_pleroma_chat_messages_url pagination_params(max_id: pagination_max_id)
      end
    end
  end

  def prev_path
    unless @messages.empty?
      api_v1_pleroma_chat_messages_url pagination_params(since_id: pagination_since_id)
    end
  end

  def pagination_max_id
    @messages.last['id']
  end

  def pagination_since_id
    @messages.first['id']
  end

  def records_continue?
    @messages.size == limit_param(DEFAULT_MESSAGES_LIMIT)
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end

  def sync_param
    params.require(:since)
  end

  def reject_blocked_recipient
    relationships_presenter = AccountRelationshipsPresenter.new([@account.id], @recipient.id)
    render json: { code: 'blocked_by_user', error: I18n.t('chats.errors.blocked_constraints') }, status: 422 if relationships_presenter.blocking[@account.id]
  end

  def set_silence_status
    @silenced = @recipient_chat_member.silenced
  end

  def reject_unfollowed_and_left_chat
    @unfollowed_and_left = false

    unless @recipient_chat_member.active
      relationships_presenter = AccountRelationshipsPresenter.new([@account.id], @recipient.id)

      unless relationships_presenter.following[@account.id]
        @unfollowed_and_left = true
        render json: { code: 'unfollowed_and_left_chat_by_user', error: I18n.t('chats.errors.unfollowed_and_left_chat_by_user') }, status: 422
      end
    end
  end

  def export_prometheus_metric
    Prometheus::ApplicationExporter.increment(:chat_messages)
  end

  def validate_media!
    return if chat_message_params[:media_ids].blank? || !chat_message_params[:media_ids].is_a?(Enumerable)

    raise Mastodon::ValidationError, I18n.t('media_attachments.validations.too_many') if chat_message_params[:media_ids].size > 4

    @media_ids = chat_message_params[:media_ids].take(4).map(&:to_i)
    @media = @account.media_attachments
                     .where(status_id: nil)
                     .where(id: @media_ids)
    raise Mastodon::ValidationError, I18n.t('media_attachments.validations.not_ready') if @media.any? { |m| !m.video? && m.not_processed? }
  end

  def send_videos_to_upload_worker
    @media.each do |m|
      UploadVideoChatWorker.perform_async(m.id) if m.video?
    end
  end

  def process_links_service
    ProcessChatLinksService.new
  end

  def validate_client
    action_assertable?
  end

  def asserting?
    request.headers['x-tru-assertion'] && action_assertable?
  end

  def action_assertable?
    %w(create).include?(action_name) ? true : false
  end

  def log_android_activity?
    current_user.user_sms_reverification_required && action_assertable?
  end


  def create_device_verification_message
    parsed_message = JSON.parse(@message)
    DeviceVerificationChatMessage.insert(verification_id: @device_verification.verification_id, message_id: parsed_message['id']) if @device_verification && parsed_message.present?
  end
end
