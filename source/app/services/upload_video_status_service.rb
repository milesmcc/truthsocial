# frozen_string_literal: true

class UploadVideoStatusService < BaseService
  include UploadVideoConcern
  include RoutingHelper

  def call(media_attachment, status)
    @media_attachment  = media_attachment
    @video             = open_video_file
    @status            = status
    @video_title       = status.id
    @video_description = status.text
    return unless @status.present? && @media_attachment.present?
    after_video_upload(send_request)
    @video.close
  end

  private

  def after_video_upload(http_response)
    parsed_json_format = http_response.parse
    video_id = parsed_json_format['video_id']
    Rails.logger.info("Rumble upload error: missing video_id. media_attachment: #{@media_attachment.id}. body: #{http_response.body}") unless video_id

    add_video_id_to_media_attachment(video_id)
    VideoPreviewWorker.perform_async(@media_attachment.id, parsed_json_format['url_monetized'])
    VideoPollingWorker.perform_async(@status.id, @media_attachment.external_video_id, parsed_json_format['url_monetized'])
  rescue => e
    Rails.logger.info("Rumble upload error: #{e.inspect}. media_attachment: #{@media_attachment.id}. #{http_response.inspect}")
    raise Mastodon::RumbleVideoUploadError
  end
end
