class StatusSuggestion < ApplicationRecord
  extend Queriable

  class << self
    def replace(*options)
      execute_query_on_master('call mastodon_api.save_status_recommendations ($1, $2)', options)
    end
  end
end
