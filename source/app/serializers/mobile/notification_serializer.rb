# frozen_string_literal: true

class Mobile::NotificationSerializer < NotificationSerializer
  include RoutingHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper

  attributes :token, :category, :platform, :message, :extend
  attribute :title, if: :chat?
  attribute :mutable_content
  attribute :thread_id, if: :chat?

  def token
    [current_push_subscription.device_token]
  end

  def preferred_locale
    current_push_subscription.associated_user&.locale || I18n.default_locale
  end

  def notification_id
    object.id
  end

  def category
    object_type
  end

  def chat?
    object.type == :chat
  end

  delegate :platform, to: :current_push_subscription

  def message
    chat? ? chat_message : I18n.t("notification_mailer.#{template}.#{notification_mailer_subject}", template_params)
  end

  def title
    "@#{object.from_account.username}"
  end

  def title_with_display_name
    object.from_account.display_name.presence || "@#{object.from_account.username}"
  end

  def mutable_content
    true
  end

  def thread_id
    chat_message_object['id']
  end

  def extend
    url = notification_url(object.type)

    if url.nil? || url.empty?
      Rails.logger.info("Empty mobile push notification status detected. Object ID: #{object.id}. Object Type: #{object.type}")
    end

    payload = []
    payload.push({ 'key' => 'truthLink', 'val' => url })
    payload.push({ 'key' => 'title', 'val' => chat? ? title_with_display_name : 'Truth Social' }) unless android?
    payload.push({ 'key' => 'accountId', 'val' => object.account_id.to_s })
    payload.push({ 'key' => 'chat', 'val' => extended_chat_fields }) if extended_chat_fields.present?
    payload.push({ 'key' => 'category', 'val' => object_type })

    if android?
      payload.push({ 'key' => 'fromAccountId', 'val' => object.from_account_id.to_s })
      payload.push({ 'key' => 'title', 'val' => android_title })
    end

    payload
  end

  def body
    str = strip_tags(object.target_status&.spoiler_text&.presence || object.target_status&.text || object.from_account.note)
    truncate(HTMLEntities.new.decode(str.to_str), length: 140) # Do not encode entities, since this value will not be used in HTML
  end

  def extended_chat_fields
    return unless chat?

    attachments = chat_message_attachments ? { 'media_attachments': chat_message_attachments } : {}
    if android?
      {
        'title': title_with_display_name,
        'chat_message_id': chat_message_object['id'],
        'chat_message_created_at': chat_message_object['created_at'],
        'from_account_id': chat_message_object['account_id'],
        **attachments,
      }
    else
      attachments
    end
  end

  def chat_message_object
    message = ChatMessage.find_message(object.account_id, object.activity.chat_id, object.activity_id)
    ActiveSupport::JSON.decode(message) if message
  end

  def chat_message
    chat_message_object['content'] ? strip_tags(chat_message_object['content']) : I18n.t("notification_mailer.chat.sent_message")
  end

  def chat_message_attachments
    chat_message_object['media_attachments']
      .pluck('id', 'type', 'preview_url')
      .map { |p| { id: p[0], type: p[1], preview_url: p[2] } } if chat_message_object['media_attachments']
  end

  private

  def notification_url(type)
    if %i(reblog
          reblog_group
          mention
          mention_group
          favourite
          favourite_group
          ).include? type
      object.target_status.uri
    elsif %i(
          follow
          follow_group).include? type
      ActivityPub::TagManager.instance.url_for(object.from_account)
    elsif %i(
          group_request
          group_approval
          group_promoted
          group_demoted
          group_delete).include? type
      ActivityPub::TagManager.instance.url_for(object.target_group)
    elsif %i(
          group_favourite
          group_favourite_group
          group_mention
          group_mention_group
          group_reblog
          group_reblog_group).include? type
      ActivityPub::TagManager.instance.url_for(object.target_status)
    elsif type == :chat
      ActivityPub::TagManager.instance.url_for_chat_message(object.activity_id)
    else
      ''
    end
  end

  def object_type
    object.type.to_s.gsub '_group', ''
  end

  def android?
    platform == 2
  end

  def notification_mailer_subject
    android? ? 'subject_android' : 'subject'
  end

  def template_params
    @template_params ||= mailer_params
  end

  def android_title
    handle = "@#{object.from_account.username}"
    if %i(group_request
          group_approval
          group_promoted
          group_demoted
          group_delete).include? object.type
      template_params[:group] || handle
    else
      handle
    end
  end
end
