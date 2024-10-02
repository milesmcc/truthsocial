# frozen_string_literal: true

class UploadVideoChatService < BaseService
  include UploadVideoConcern
  include RoutingHelper

  def call(media_attachment)
    @media_attachment  = media_attachment
    @video             = open_video_file
    @video_title       = 'dm'
    @video_description = 'dm'
    return if @media_attachment.blank?
    after_video_upload(send_request)
    @video.close
  end

  private

  def after_video_upload(http_response)
    parsed_json_format = http_response.parse
    add_video_id_to_media_attachment(parsed_json_format['video_id'])
  end
end
