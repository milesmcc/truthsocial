# frozen_string_literal: true
require "./lib/proto/status_created_pb.rb"

class StatusCreatedEvent
  include RoutingHelper
  EVENT_KEY = "truth_events:v1:status:created".freeze

  def initialize(status)
    @status = status
  end

  def serialize
    StatusCreated.encode(protobuf)
  end

  private

  attr_reader :status

  def protobuf
    StatusCreated.new(
      id: status.id,
      account_id: status.account_id,
      text: status.text,
      media_attachments: media_attachment_protobufs
    )
  end

  def media_attachment_protobufs
    status.media_attachments.map do |attachment|
      StatusCreated::MediaAttachment.new(
        id: attachment.id,
        url: url(attachment),
        type: attachment.type
      )
    end
  end

  def url(media_attachment)
    if media_attachment.not_processed?
      nil
    elsif media_attachment.needs_redownload?
      media_proxy_url(media_attachment.id, :original)
    else
      full_asset_url(media_attachment.file.url(:original))
    end
  end
end
