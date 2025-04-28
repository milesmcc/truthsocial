# frozen_string_literal: true

class REST::V2::Status::TagSerializer < Panko::Serializer
  include RoutingHelper

  attributes :name, :url

  def url
    tag_url(object)
  end
end
