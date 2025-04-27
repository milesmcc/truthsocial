# frozen_string_literal: true

class REST::V2::TombstoneSerializer < Panko::Serializer
  include RoutingHelper

  attributes :reason

  def reason
    'deleted'
  end

end