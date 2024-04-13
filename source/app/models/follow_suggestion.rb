class FollowSuggestion < ApplicationRecord
  extend Queriable

  class << self
    def replace(*options)
      execute_query_on_master('call mastodon_api.save_follow_recommendations ($1, $2)', options)
    end
  end
end