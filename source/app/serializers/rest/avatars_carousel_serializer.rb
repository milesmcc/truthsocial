# frozen_string_literal: true

class REST::AvatarsCarouselSerializer < ActiveModel::Serializer
  include RoutingHelper

  attributes :account_id, :account_avatar, :acct, :seen

  def account_id
    object.id.to_s
  end

  def account_avatar
    full_asset_url(object.suspended? ? object.avatar.default_url : object.avatar_original_url)
  end

end
