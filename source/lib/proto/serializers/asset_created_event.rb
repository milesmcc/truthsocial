# frozen_string_literal: true

class AssetCreatedEvent
  include RoutingHelper

  def initialize(asset)
    @asset = asset
  end

  def serialize
    AssetCreated.encode(protobuf)
  end

  def p
    protobuf
  end

  private

  attr_reader :asset

  def protobuf
    AssetCreated.new(
      id: asset.id,
      account_id: asset.account_id,
      url: asset.file.url,
      type: determine_asset_type(asset)
    )
  end

  def determine_asset_type(asset)
    AssetCreated.new(type: asset.type.upcase.to_sym)

    return asset.type.upcase.to_sym

  rescue RangeError => e
    return :UNKNOWN if e.message == "Unknown symbol value for enum field 'type'."

    raise e
  end
end
