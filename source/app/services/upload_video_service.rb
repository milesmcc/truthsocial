# frozen_string_literal: true

class UploadVideoService < BaseService
  include RoutingHelper

  VIDEO_UPLOAD_URL = ENV["VIDEO_UPLOAD_URL"]
  VIDEO_UPLOAD_KEY = ENV["VIDEO_UPLOAD_KEY"]

  def call(media_attachment, status)
    @media_attachment = media_attachment
    @url              = VIDEO_UPLOAD_URL
    @key              = VIDEO_UPLOAD_KEY
    @video            = open_video_file
    @status           = status

    return unless @url.present? && @key.present?
    return unless @status.present? && @media_attachment.present?

    create_preview_card(send_request)
    @video.close
  end

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
      access_token: @key,
      title: "Video upload for #{@status.id}",
      description: "This is a video for #{@status.text}",
      license_type: 0,
      guid: @media_attachment.id,
      video: HTTP::FormData::File.new(@video.path)
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
  def create_preview_card(http_response)
    parsed_json_format = http_response.parse
    add_video_id_to_media_attachment(parsed_json_format["video_id"])
    LinkCrawlWorker.perform_async(@status.id, parsed_json_format["url_monetized"])
  end

  def open_video_file
    tempfile = Tempfile.new(['video_file', uploaded_file_extension])
    @media_attachment.file.copy_to_local_file(:original, tempfile.path)
    tempfile
  end

  def send_request
    HTTP.headers(:accept => "multipart/form-data").post(@url, form: construct_request)
  end

  def uploaded_file_extension
    ".#{@media_attachment.file_file_name.split('.').last}"
  end
end
