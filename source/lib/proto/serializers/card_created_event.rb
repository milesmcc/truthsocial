# frozen_string_literal: true
require "./lib/proto/card_created_pb.rb"

class CardCreatedEvent
  include RoutingHelper
  EVENT_KEY = "truth_events:v1:card:created".freeze

  def initialize(card)
    @card = card
  end

  def serialize
    CardCreated.encode(protobuf)
  end

  private

  attr_reader :card

  def protobuf
    CardCreated.new(
      id: card.id,
      title: card.title,
      description: card.description,
      author_name: card.author_name,
      provider_name: card.provider_name,
      image_url: image,
      status_ids: status_ids
    )
  end

  def image
    card.image? ? full_asset_url(card.image.url(:original)) : nil
  end

  def status_ids
    @card.statuses.pluck(:id)
  end
end
