# frozen_string_literal: true

class REST::RuleSerializer < ActiveModel::Serializer
  attributes :id, :text, :subtext, :rule_type

  def id
    object.id.to_s
  end
end
