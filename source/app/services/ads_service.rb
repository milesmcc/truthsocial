# frozen_string_literal: true

class AdsService < BaseService
  include Redisable
  include Rails.application.routes.url_helpers

  ADS_PER_ZONE = 15
  API_URL = ENV.fetch('RUMBLE_ADS_URL', false)
  WHY_COPY = I18n.t('ads.why_copy')

  ZONES = { desktop: [33, 35],
           mobile: [34, 36] }

  def call(device, request)
    @request = request
    @all_ads = []

    device = :mobile unless %i(mobile desktop).include? device
    ZONES[device].each do |zone|
      api_url = construct_url(zone)
      response = send_request(api_url)
      parse_response(response)
    end

    create_response
  end

  def self.track_impression(params, request)
    provider_params = { 'rumble' => %w(path),
                    'revcontent' => %w(rev_position rev_response_id rev_impression_hash) }

    provider = params.key?('provider') && provider_params.key?(params['provider']) ? params['provider'] : 'rumble'

    store_impression_stats(provider, params)

    platform = request.user_agent.strip.start_with?('TruthSocial/') ? 1 : 0

    worker = "Track#{provider.capitalize}AdImpressionsWorker".constantize
    worker_params = params.permit(provider_params[provider]).to_h
    worker_params[:platform] =  platform
    worker.perform_async(worker_params)
  end

  private

  def self.store_impression_stats(provider, params)
    today = Time.now.strftime('%Y-%m-%d')
    expire_after = 7.days.seconds

    Redis.current.incr("ads-impressions-#{provider}-attempts:#{today}")
    Redis.current.expire("ads-impressions-#{provider}-attempts:#{today}", 7.days.seconds)

    Redis.current.zincrby("ads-impressions-#{provider}-sources:#{today}", 1, params['source'])
    Redis.current.expire("ads-impressions-#{provider}-sources:#{today}", expire_after)

    Redis.current.zincrby("ads-impressions-#{provider}-positions:#{today}", 1, params['position'])
    Redis.current.expire("ads-impressions-#{provider}-positions:#{today}", expire_after)

    Redis.current.zincrby("ads-impressions-#{provider}-indexes:#{today}", 1, params['index'])
    Redis.current.expire("ads-impressions-#{provider}-indexes:#{today}", expire_after)
  end

  def construct_url(zone)
    return unless API_URL

    params = {
      count: ADS_PER_ZONE,
      ip:  @request.remote_ip,
      html: :no,
      ua: @request.user_agent,
    }

    api_url = API_URL.sub ':id', zone.to_s
    api_url << "?#{params.to_query}"
  end

  def send_request(url)
    HTTP.headers('Accept-Language' => @request.headers['HTTP_ACCEPT_LANGUAGE']).timeout(1).get(url)
  rescue StandardError => e
    Rails.logger.info("Ads error:  #{e}, URL: #{url}")
    false
  end

  def parse_response(response)
    return unless response

    begin
      json_response = JSON.parse(response)
    rescue StandardError => e
      Rails.logger.info("Ads error:  #{e}, response: #{response}")
      false
    end
    return unless json_response && json_response.key?('count') && json_response.key?('ads') && json_response['count'].to_i.positive?
    @all_ads.push(json_response['ads'])
  end

  def create_response
    ads_to_return = prioritize_first_zone(@all_ads)
    ads_to_return = default_ads if ads_to_return.length.zero?
    ads_response = []

    ads_to_return.each_with_index do |ad, index|
      next unless ad.key?('type') && ad.key?('impression') && ad.key?('click') && ad.key?('asset') && ad.key?('expires')
      ads_response.push({  type: ad['type'],
                           impression: create_impression_url(ad['impression'], index),
                           click: ad['click'],
                           asset: ad['asset'],
                           expires: calculate_expiration(ad['expires']),
                           why_copy: WHY_COPY })
    end

    Rails.logger.info('Ads error:  Returning 0 ads') if ads_response.length.zero?

    { count: ads_to_return.count, ads: ads_response }
  end

  def zip_ads(zone_ads)
    zone_ads.sort! { |x, y| y.length <=> x.length }
    longest_zone = zone_ads.shift || []
    longest_zone.zip(*zone_ads).flatten.compact
  end

  def prioritize_first_zone(zone_ads)
    return zone_ads.flatten unless zone_ads[0] && zone_ads[1]

    enum = Enumerator.new do |y|
      e1 = zone_ads[0].each
      e2 = zone_ads[1].each
      loop do
        y << e1.next << e1.next << e1.next << e2.next
      end
    end

    enum.to_a
  end

  def default_ads
    redis_ads = redis.zrange('in-house-ads', 0, -1)
    ads = []
    redis_ads.each do |ad|
      parsed = JSON.parse(ad)
      next unless parsed.is_a?(Hash)
      parsed['expires'] = Time.now.to_i + parsed[:expires].to_i
      ads.push(parsed)
    rescue JSON::ParserError => e
      Rails.logger.info("Ads error:  #{e}, ad to parse: #{ad}")
      next
    end
    ads
  end

  def create_impression_url(url, index)
    parsed_url = Addressable::URI.parse(url)
    path = CGI.escape(parsed_url.request_uri) if parsed_url.respond_to?(:request_uri)
    "#{api_v1_truth_ads_impression_url}/?path=#{path}&index=#{index}"
  rescue Addressable::URI::InvalidURIError => e
    Rails.logger.info("Ads error: Invalid impression url #{url} #{e}")
    url
  end

  def calculate_expiration(ad_expiration_epoch)
    new_expiration_seconds = Redis.current.get('ads-expiration-minutes').to_i.minutes.seconds.to_i
    return ad_expiration_epoch if new_expiration_seconds.zero?

    new_expiration_epoch = Time.current.to_i + new_expiration_seconds
    new_expiration_epoch > ad_expiration_epoch ? ad_expiration_epoch : new_expiration_epoch
  end

  private_class_method :store_impression_stats
end
