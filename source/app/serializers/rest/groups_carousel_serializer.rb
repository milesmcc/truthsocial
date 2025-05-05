# frozen_string_literal: true

class REST::GroupsCarouselSerializer < Panko::Serializer
  include RoutingHelper

  attributes :group_id, :group_avatar, :display_name, :seen, :visibility

  def group_id
    object.id.to_s
  end

  def group_avatar
    full_asset_url(object.deleted_at ? object.avatar.default_url : object.avatar_original_url)
  end

  def visibility
    object.statuses_visibility
  end

  delegate :seen, to: :object
end
