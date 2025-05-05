# frozen_string_literal: true

class ChatMessageReaction < ApplicationRecord
  MAX_MESSAGES_PER_MIN = ENV.fetch('MAX_REACTIONS_PER_MIN', 10).to_i.freeze

  extend Queriable

  class << self
    def find(*options)
      execute_query('select mastodon_chats_api.message_reaction_info ($1, $2, $3)', options).to_a.first['message_reaction_info']
    end

    def create!(*options)
      execute_query_on_master('select mastodon_chats_api.message_reaction_add ($1, $2, $3)', options).to_a.first['message_reaction_add']
    end

    def destroy!(*options)
      execute_query_on_master('select mastodon_chats_api.message_reaction_remove ($1, $2, $3)', options).to_a.first['message_reaction_remove']
    end
  end
end
