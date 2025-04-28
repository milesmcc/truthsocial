class ChatEvent < ApplicationRecord
  include Paginable
  extend Queriable

  class << self
    def load_events(*options)
      execute_query('select mastodon_chats_api.events ($1, $2, $3, $4, $5, $6, $7, $8)', options).to_a.first['events']
    end
  end
end
