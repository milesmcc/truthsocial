# frozen_string_literal: true

class REST::OauthTokenSerializer < Panko::Serializer
  attributes :app_name, :id, :created_at, :current_token

  def app_name
    object.name
  end

  def current_token
    context[:current_token] == object
  end
end
