class REST::Admin::StatusSerializer < REST::StatusSerializer
  attributes :deleted_by_id, :deleted_at
end
