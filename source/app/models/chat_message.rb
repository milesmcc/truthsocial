# == Schema Information
#
# Table name: chats.messages
#
#  message_id            :bigint(8)        not null, primary key
#  chat_id               :integer          not null
#  message_type          :enum             default("text"), not null
#  created_at            :datetime         not null
#  expiration            :interval         default(0 seconds), not null
#  created_by_account_id :bigint(8)        not null
#
class ChatMessage < ApplicationRecord
  belongs_to :chat, touch: true
  self.table_name = 'chats.messages'
  self.primary_key = :message_id
  self.inheritance_column = false
  self.record_timestamps = false

  attr_accessor :content, :unread, :account_id, :emoji_reactions, :idempotency_key, :media_attachments

  include Paginable
  extend Queriable

  MAX_CHARS = ENV.fetch('MAX_CHAT_CHARS', 500).to_i.freeze
  MAX_MESSAGES_PER_MIN = ENV.fetch('MAX_MESSAGES_PER_MIN', 20).to_i.freeze

  def save(*)
    true
  end

  class << self
    def create_by_function!(**options)
      validate_content_length(options[:content], options[:media_attachment_ids])
      message = execute_query_on_master('select mastodon_chats_api.message_create ($1, $2, $3, $4, $5, $6)', format_options(options)).to_a.first['message_create']

      publish_chat_message('create', JSON.parse(message))
      message
    end

    def load_messages(*options)
      execute_query('select mastodon_chats_api.messages ($1, $2, $3, $4, $5, $6)', options).to_a.first['messages']
    end

    def find_message(*options)
      execute_query('select mastodon_chats_api.message ($1, $2, $3)', options).to_a.first['message']
    end

    def find_message_with_context(*options)
      execute_query('select mastodon_chats_api.message_with_context ($1, $2, $3)', options).to_a.first['message_with_context']
    end

    # options = account_id, message_id
    def destroy_message!(*options)
      execute_query_on_master('select mastodon_chats_api.message_delete ($1, $2)', options).to_a.first['message_delete']
    end

    def deleted_since(*options)
      execute_query('select mastodon_chats_api.message_modifications ($1, $2, $3)', options).to_a.first['message_modifications']
    end

    def visible_messages(*options)
      execute_query('select mastodon_chats_api.messages_visible ($1, $2)', options).to_a.first['messages_visible']
    end

    def publish_chat_message(type, message)
      created_by_account_id = message['account_id'] || message.created_by_account_id
      return unless subscribed_to_timeline?(created_by_account_id)

      chat_id = message['chat_id'] || message.chat_id
      message_id = message['id'] || message.id

      PushChatMessageWorker.perform_async(chat_id, type, created_by_account_id, message_id)
    end

    private

    def format_options(options)
      options.map { |_key, value| value }
    end

    def validate_content_length(content, media_attachments)
      return if content.blank? && media_attachments.present?

      raise Mastodon::UnprocessableEntityError, "Content can't be blank" if content.blank?
      raise Mastodon::UnprocessableEntityError, 'Content is too long (maximum is 500 characters)' if content.grapheme_clusters.length > MAX_CHARS
    end

    def subscribed_to_timeline?(account_id)
      Redis.current.exists?("subscribed:timeline:#{account_id}")
    end
  end
end
