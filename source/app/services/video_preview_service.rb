# frozen_string_literal: true

class VideoPreviewService
  PREVIEW_OPTIONS = {
    endpoint: 'https://rumble.com/api/Media/oembed.json?url={url}',
    format: :json,
  }.freeze

  #
  # Fetches the prview data for a video URL from Rumble and updates the given
  # media attachment's thumbnail URL.
  #
  # @param media_attachment [MediaAttachment] The media attachment to update.
  # @param url [String] The URL of the video to fetch the preview data for.
  #
  # @raise [Mastodon::UnexpectedResponseError] If the fetched embed data does not contain
  # a thumbnail URL.
  #
  def call(media_attachment, url)
    service = FetchOEmbedService.new
    embed = service.call(url, cached_endpoint: PREVIEW_OPTIONS)
    raise Mastodon::UnexpectedResponseError, service.endpoint_url if embed[:thumbnail_url].blank?

    media_attachment.update!(thumbnail_remote_url: embed[:thumbnail_url])
  end
end
