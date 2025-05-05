# frozen_string_literal: true
module PTv::ApiConcern
  extend ActiveSupport::Concern
  include Redisable

  USERNAME = ENV.fetch('TV_USERNAME', '')
  PASSWORD = ENV.fetch('TV_PASSWORD', '')
  VERSION = ENV.fetch('TV_VERSION', '10.1')
  FORMAT = ENV.fetch('TV_FORMAT', 'json')
  SESSION_ID = ENV.fetch('TV_DEFAULT_SESSION', '')

  private

  def send_post_request(parameters, resource)
    generate_post_digest(parameters, resource)
    api_url = "#{@base_url}Catherine/api/#{VERSION}/#{FORMAT}/#{@client_id}/#{@digest}/#{resource}"

    uri = URI.parse(api_url)
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
    request.body = parameters.to_json

    http.use_ssl = true
    res = http.request(request)

    res

    # TODO: add timeout
  rescue HTTP::Error, HTTP::TimeoutError, HTTP::ConnectionError, StandardError => e
    Rails.logger.info("Tv error' =>#{e}, URL: #{api_url}")
    false
  end

  def generate_post_digest(parameters, resource)
    @digest = Digest::MD5.hexdigest("#{@secret}#{VERSION}#{FORMAT}#{@client_id}#{resource}#{parameters.to_json}")
  end

  def send_get_request(parameters, resource)
    # TODO: Use the same approach as the POST requests
    generate_get_digest(parameters, resource)
    api_url = "#{@base_url}Catherine/api/#{VERSION}/#{FORMAT}/#{@client_id}/#{@digest}/#{resource}?#{parameters.to_query}"

    HTTP.timeout(5).headers('Content-Type' => 'application/json', 'Accept' => 'application/json').get(api_url)
  rescue HTTP::Error, HTTP::TimeoutError, HTTP::ConnectionError, StandardError => e
    Rails.logger.info("Tv error' =>#{e}, URL: #{api_url}")
    false
  end

  def generate_get_digest(parameters, resource)
    @digest = Digest::MD5.hexdigest("#{@secret}#{VERSION}#{FORMAT}#{@client_id}#{resource}#{parameters.values.join}")
  end

  def parse_response(response, key)
    return unless response

    begin
      json_response = JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.info("Tv error. Can't parse:  #{e}, response: #{response}")
      false
    end
    return unless json_response && json_response.key?(key)
    json_response[key]
  end
end
