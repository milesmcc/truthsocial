# frozen_string_literal: true

module UploadVideoConcern
  extend ActiveSupport::Concern
  include RoutingHelper

  VIDEO_UPLOAD_URL = ENV['VIDEO_UPLOAD_URL']
  VIDEO_UPLOAD_KEY = ENV['VIDEO_UPLOAD_KEY']
  VIDEO_STATUS_URL = ENV['VIDEO_STATUS_URL']

  @video_title = ''
  @video_description = ''

  private

  def add_video_id_to_media_attachment(video_id)
    @media_attachment.external_video_id = "v#{video_id}"
    @media_attachment.save
  end

  # Accepts multipart/form-data content with the following fields:
  # access_token: required string, 40 characters
  # title: required string
  # description: required string
  # license_type: required integer, 0 for "not for sale", 6 for "Rumble only"
  # channel_id: optional integer
  # guid: optional string, this should be your own internal ID for the video for mapping
  # thumb: optional thumbnail file
  # video: video file
  # cc_<language-code>: close captions file, e.g. cc_en, cc_es, cc_fr etc. You can upload multiple files for different languages at once. We support the following formats: vtt, srt, sbv, stl, sub.
  def construct_request
    {
      access_token: VIDEO_UPLOAD_KEY,
      title: "Video upload for #{@video_title}",
      description: "This is a video for #{@video_description}",
      license_type: 0,
      guid: @media_attachment.id,
      video: HTTP::FormData::File.new(@video.path),
    }
  end

  # {
  #   "success": true,
  #   "video_id": "oaf3l",
  #   "video_id_int": 40796913,
  #   "url_monetized": "https://rumble.com/vqwl7r-ladies-and-gentlemen.html?mref=ummtf&mc=3nvg0",
  #   "embed_url_monetized": "https://rumble.com/embed/voaf3l/?pub=ummtf",
  #   "embed_html_monetized": "<iframe class=\"rumble\" width=\"640\" height=\"360\" src=\"https://rumble.com/embed/voaf3l/?pub=ummtf\" frameborder=\"0\" allowfullscreen></iframe>",
  #   "embed_js_monetized": "<script>!function(r,u,m,b,l,e){r._Rumble=b,r[b]||(r[b]=function(){(r[b]._=r[b]._||[]).push(arguments);if(r[b]._.length==1){l=u.createElement(m),e=u.getElementsByTagName(m)[0],l.async=1,l.src=\"https://rumble.com/embedJS/uummtf\"+(arguments[1].video?'.'+arguments[1].video:'')+\"/?url=\"+encodeURIComponent(location.href)+\"&args=\"+encodeURIComponent(JSON.stringify([].slice.apply(arguments))),e.parentNode.insertBefore(l,e)}})}(window, document, \"script\", \"Rumble\");</script>\n\n<div id=\"rumble_voaf3l\"></div>\n<script>\nRumble(\"play\", {\"video\":\"voaf3l\",\"div\":\"rumble_voaf3l\"});</script>"
  # }

  def open_video_file
    tempfile = Tempfile.new(['video_file', uploaded_file_extension])
    @media_attachment.file.copy_to_local_file(:original, tempfile.path)
    tempfile
  end

  def send_request
    HTTP.headers(accept: 'multipart/form-data').post(VIDEO_UPLOAD_URL, form: construct_request)
  rescue => e
    Rails.logger.info("Rumble upload error: #{e.inspect}. media_attachment: #{@media_attachment.id}")
    raise Mastodon::RumbleVideoUploadError
  end

  def uploaded_file_extension
    ".#{@media_attachment.file_file_name.split('.').last}"
  end

  def video_encoded?
    http_response = HTTP.timeout(3).get(VIDEO_STATUS_URL + @video_id)
    parsed_json_format = http_response.parse
    assets = parsed_json_format['assets']
    assets.present? && assets['video'].present?
  end
end
