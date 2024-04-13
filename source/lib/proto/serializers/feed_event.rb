# frozen_string_literal: true
class FeedEvent
  include RoutingHelper

  def initialize(feed, fields_changed)
    @feed = feed
    @fields_changed = fields_changed
  end

  def serialize
    Proto::Feed.encode(protobuf)
  end

  private

  attr_reader :feed, :fields_changed

  def protobuf
    Proto::Feed.new(
      id: feed.id,
      name: feed.name,
      description: feed.description,
      visibility: feed.visibility,
      fields_changed: fields_changed
    )
  end
end
