# frozen_string_literal: true

class REST::V2::GroupSerializer < Panko::Serializer
  include RoutingHelper
  include DiscardedHelper

  attributes :id, :locked, :display_name, :created_at, :note,
             :avatar, :avatar_static, :header, :header_static,
             :group_visibility, :membership_required,
             :note, :discoverable, :members_count, :slug,
             :tags, :source, :url, :owner, :deleted_at

  def id
    object.id.to_s
  end

  def locked
    object.locked?
  end

  def display_name
    context&.dig(:admin) ? object.display_name : attribute_or_discarded_value(object.display_name, '')
  end

  def note
    Formatter.instance.linkify(object.note)
  end

  def avatar
    attribute_or_discarded_value(full_asset_url(object.avatar_original_url), full_asset_url(avatar_missing_url))
  end

  def avatar_static
    attribute_or_discarded_value(full_asset_url(object.avatar_static_url), full_asset_url(avatar_missing_url))
  end

  def header
    attribute_or_discarded_value(full_asset_url(object.header_original_url), full_asset_url(header_missing_url))
  end

  def header_static
    attribute_or_discarded_value(full_asset_url(object.header_static_url), full_asset_url(header_missing_url))
  end

  def group_visibility
    object.statuses_visibility
  end

  def created_at
    object.created_at.midnight.as_json
  end

  def emojis
    object.emojis
  end

  def membership_required
    true
  end

  def tags
    only_pinned = object.tags.where.not(group_tags: { group_tag_type: :hidden })
    Panko::ArraySerializer.new(context && context[:only_pinned_tags] ? only_pinned : object.tags, each_serializer: REST::V2::TagSerializer).to_a
  end

  def source
    { note: object.note }
  end

  def owner
    context&.dig(:owner_avatar) ? REST::GroupsAvatarSerializer.new.serialize(object.owner_account) : { id: object.owner_account_id.to_s }
  end

  def url
    attribute_or_discarded_value(object.url, '')
  end

  delegate :members_count, to: :object

  private

  def avatar_missing_url
    '/groups/avatars/original/missing.png'
  end

  def header_missing_url
    '/groups/headers/original/missing.png'
  end
end
