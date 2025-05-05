class REST::GroupsAvatarSerializer < Panko::Serializer
  include RoutingHelper

  attributes :id,
             :username,
             :avatar

  def id
    object.id.to_s
  end

  def avatar
    full_asset_url(object.avatar_original_url)
  end
end
