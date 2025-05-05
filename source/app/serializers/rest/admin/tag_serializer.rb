class REST::Admin::TagSerializer < REST::TagSerializer
  attributes :id, :last_status_at, :max_score, :max_score_at, :name
end
