# frozen_string_literal: true

class CardJoinedEvent
  include RoutingHelper

  def initialize(card)
    @card = card
  end

  def serialize
    CardJoined.encode(protobuf)
  end

  private

  attr_reader :card

  def protobuf
    CardJoined.new(
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
