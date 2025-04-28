# frozen_string_literal: true
class PTv::Client::GetEpgService < PTv::Client::Api
  def call(channel_ids, start_time, end_time)
    @channel_ids = channel_ids
    @start_time = start_time
    @end_time = end_time
    response = send_request
    parse_response(response, 'entries')
  end

  private

  def send_request
    parameters = {
      channelId: @channel_ids,
      endTime: @end_time,
      imageInfo: [{ height: 250, width: 550 }],
      includeBookmarks: true,
      includeShow: true,
      locale: 'en-GB',
      preferredOriginalTitle: 'NONE',
      startTime: @start_time,
    }
    send_post_request(parameters, 'client/tv/getEpg')
  end
end
