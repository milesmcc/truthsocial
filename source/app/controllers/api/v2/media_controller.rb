# frozen_string_literal: true

class Api::V2::MediaController < Api::V1::MediaController
  def create
    @media_attachment = current_account.media_attachments.create!({ delay_processing: true }.merge(media_attachment_params))
    export_prometheus_metric
    render json: @media_attachment, serializer: REST::MediaAttachmentSerializer, status: 202
  rescue Paperclip::Errors::NotIdentifiedByImageMagickError
    render json: file_type_error, status: 422
  rescue Paperclip::Error
    render json: processing_error, status: 500
  end

  private
  def export_prometheus_metric
    Prometheus::ApplicationExporter::increment(:media_uploads, {type: @media_attachment.type})
  end
end
