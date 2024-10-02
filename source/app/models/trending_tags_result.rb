class TrendingTagsResult < ApplicationRecord
  include Paginable
  extend Queriable

  class << self
    def load_results(*options)
      execute_query('select * from mastodon_api.trending_tags ($1, $2)', options).to_a.first['trending_tags']
    end
  end
end
