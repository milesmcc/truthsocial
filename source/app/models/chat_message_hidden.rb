class ChatMessageHidden < ApplicationRecord
  extend Queriable

  class << self
    # options = account_id, message_id
    def hide_message(*options)
      execute_query_on_master('select mastodon_chats_api.message_hide ($1, $2)', options).to_a.first['message_hide']
    end

    # options = account_id, message_id
    def unhide_message(*options)
      execute_query_on_master('select mastodon_chats_api.message_unhide ($1, $2)', options).to_a.first['message_unhide']
    end
  end
end
