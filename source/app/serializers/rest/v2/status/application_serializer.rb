# frozen_string_literal: true

class REST::V2::Status::ApplicationSerializer < Panko::Serializer
  attributes :name,
             :website
end
