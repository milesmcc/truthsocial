# frozen_string_literal: true
class GroupEvent
  include RoutingHelper

  def initialize(group, fields_changed)
    @group = group
    @fields_changed = fields_changed
  end

  def serialize
    Proto::Group.encode(protobuf)
  end

  private

  attr_reader :group, :fields_changed

  def protobuf
    Proto::Group.new(
      id: group.id,
      display_name: group.display_name,
      avatar_url: full_asset_url(group.avatar_original_url),
      header_url: full_asset_url(group.header_static_url),
      description: group.note,
      slug: group.slug,
      fields_changed: fields_changed
    )
  end
end
