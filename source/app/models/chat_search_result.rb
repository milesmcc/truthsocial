class ChatSearchResult < ApplicationRecord
  include Paginable
  extend Queriable

  class << self
    def load_results(*options)
      execute_query('select mastodon_chats_api.search_chats_and_followers ($1, $2, $3, $4)', options).to_a.first['search_chats_and_followers']
    end

    def load_message_results(*options)
      execute_query('select mastodon_chats_api.search_chat_messages ($1, $2, $3, $4)', options).to_a.first['search_chat_messages']
    end

    def load_message_previews(*options)
      execute_query('select mastodon_chats_api.search_preview ($1, $2)', options).to_a.first['search_preview']
    end
  end
end
