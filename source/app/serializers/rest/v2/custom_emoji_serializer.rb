# frozen_string_literal: true

class REST::V2::CustomEmojiSerializer < Panko::Serializer
  include RoutingHelper

  attributes :shortcode,
             :url,
             :static_url,
             :visible_in_picker,
             :category

  def url
    full_asset_url(object.image.url)
  end

  def static_url
    full_asset_url(object.image.url(:static))
  end

  def category
    object.category.name if category_loaded?
  end

  def category_loaded?
    object.association(:category).loaded? && object.category.present?
  end
end
