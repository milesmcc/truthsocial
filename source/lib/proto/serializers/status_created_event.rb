# frozen_string_literal: true

class StatusCreatedEvent
  include RoutingHelper

  def initialize(status, ip_address)
    @status = status
    @ip_address = ip_address
  end

  def serialize
    StatusCreated.encode(protobuf)
  end

  private

  attr_reader :status, :ip_address

  def protobuf
    StatusCreated.new(
      id: status.id,
      account_id: status.account_id,
      text: status.text,
      media_attachments: media_attachment_protobufs,
      ip_address: ip_address,
      group_id: status.group_id
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
    if media_attachment.type != "video" && media_attachment.not_processed?
      nil
    elsif media_attachment.needs_redownload?
      media_proxy_url(media_attachment.id, :original)
    else
      full_asset_url(media_attachment.file.url(:original))
    end
  end
end
