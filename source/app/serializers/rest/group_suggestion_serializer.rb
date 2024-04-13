# frozen_string_literal: true

class REST::GroupSuggestionSerializer < Panko::Serializer
  attributes :id,
             :group_id,
             :created_at

  def id
    object.id.to_s
  end

  def group_id
    object.group_id.to_s
  end
end
