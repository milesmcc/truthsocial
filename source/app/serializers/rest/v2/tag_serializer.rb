# frozen_string_literal: true

class REST::V2::TagSerializer < Panko::Serializer
  include RoutingHelper

  attributes :id, :name

  def id
    object.id.to_s
  end
end
