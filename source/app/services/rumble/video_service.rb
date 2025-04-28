class Rumble::VideoService
  VIDEO_STATUS_URL = ENV['VIDEO_STATUS_URL']

  attr_reader(:status, :video)

  def initialize(id)
    @id = id
  end

  def perform
    response = HTTP.timeout(5).headers('Content-Type' => 'application/json', 'Accept' => 'application/json').get(endpoint)
    @status = response.code
    @video = response.parse
  rescue => e
    Rails.logger.error("Rumble service error: #{e}.  video_id: #{@id}, code: #{response&.code}. body: #{response&.body&.to_s}")
  end

  private

  attr_reader(:id)

  def request
    @request ||= Request.new(:get, endpoint)
  end

  def endpoint
    VIDEO_STATUS_URL + @id
  end
end