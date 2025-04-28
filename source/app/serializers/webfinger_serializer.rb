# frozen_string_literal: true

class WebfingerSerializer < ActiveModel::Serializer
  include RoutingHelper

  attributes :subject, :aliases, :links

  def subject
    object.to_webfinger_s
  end

  def aliases
    [short_account_url(object), account_url(object)]
  end

  def links
    [
      { rel: 'http://webfinger.net/rel/profile-page', type: 'text/html', href: short_account_url(object) },
      { rel: 'self', type: 'application/activity+json', href: account_url(object) },
      # { rel: 'http://ostatus.org/schema/1.0/subscribe', template: "#{authorize_interaction_url}?uri={uri}" },
    ]
  end
end
