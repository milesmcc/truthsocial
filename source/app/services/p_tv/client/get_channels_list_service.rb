# frozen_string_literal: true
class PTv::Client::GetChannelsListService < PTv::Client::Api
  def call
    response = send_request
    parse_response(response, 'channels')
  end

  private

  def send_request
    playback_formats = [
      {
        'protocol' => 'HLS',
        'audioFormats' => [
          'AAC',
        ],
        'container' => 'TS',
        'videoCodecs' => [
          'H264',
        ],
        'drmTypes' => [
          'CLEAR_KEY',
        ],
        'subtitleFormats' => [
          'WEBVTT',
        ],
      },
      {
        'protocol' => 'HLS',
        'audioFormats' => [
          'AAC',
        ],
        'container' => 'MP4',
        'videoCodecs' => [
          'H264',
        ],
        'drmTypes' => [
          'WIDEVINE',
        ],
        'encryptionMethods' => %w(CBCS_AES_CBC CENC_AES_CTR),
        'subtitleFormats' => [
          'WEBVTT',
        ],
      },
    ]

    image_info = [
      {
        'type' => 'DARK',
        'height' => 35,
        'width' => 49,
      },
      {
        'type' => 'LIGHT',
        'height' => 35,
        'width' => 49,
      },
      {
        'type' => 'AVERAGE_COLOR',
        'height' => 193,
        'width' => 273,
      },
      {
        'type' => 'DARK',
        'height' => 193,
        'width' => 273,
      },
    ]

    parameters = { imageInfo: image_info, locale: 'en-GB', profileGuid: @tv_profile_id, playbackFormats: playback_formats, sessionId: @session_id, type: 'TV' }
    send_post_request(parameters, 'client/channels/list')
  end
end
