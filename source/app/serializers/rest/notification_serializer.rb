# frozen_string_literal: true

class REST::NotificationSerializer < ActiveModel::Serializer
  attributes :id, :type, :total_count, :created_at
  attribute :total_count, if: -> { object.count.present? }
  attribute :target_chat_message, if: -> { object.type == :chat || object.type == :chat_message_deleted }
  attribute :target_status, key: :status, if: :status_type?

  belongs_to :from_account, key: :account, serializer: REST::AccountSerializer

  def id
    object.id.to_s
  end

  def type
    object.type.to_s.gsub '_group', ''
  end

  def total_count
    object.count
  end

  def target_status
    REST::V2::StatusSerializer.new(context: { current_user: instance_options[:current_user] }).serialize(object.target_status) if object.target_status
  end

  def status_type?
    [:favourite, :favourite_group, :group_favourite, :group_favourite_group,
     :reblog, :reblog_group, :group_reblog, :group_reblog_group,
     :status,
     :mention, :mention_group, :group_mention, :group_mention_group,
     :poll].include?(object.type)
  end

  def target_chat_message
    chat_message = ChatMessage.find_message(object.account_id, object.activity.chat_id, object.activity_id)

    if chat_message
      decoded = ActiveSupport::JSON.decode(chat_message)
      chat_message_obj = ChatMessage.new(decoded)

      ActiveModelSerializers::SerializableResource.new(chat_message_obj, serializer: REST::ChatMessageSerializer).as_json
    end
  end
end
