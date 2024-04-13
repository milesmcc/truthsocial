class StatusReplies < ApplicationRecord
  extend Queriable

  class << self
    def descendants(*options)
      execute_query('select mastodon_logic.status_replies ($1, $2, $3, $4, $5)', options).to_a.map { |x| x['status_replies'] }
    end
  end
end
