# frozen_string_literal: true

class TrackRevcontentAdImpressionsWorker
  include Sidekiq::Worker
  include Redisable
  include TrackAdImpressionsConcern

  sidekiq_options queue: 'ads', retry: 3

  API_URL = ENV.fetch('REVCONTENT_ADS_URL', false)
  VIEWS_PATH = 'view.php'
  IMPRESSIONS_PATH = 'api/v2/track.php'

  def perform(params)
    @provider = 'revcontent'
    @parsed_url = Addressable::URI.parse(API_URL)

    @position = params['rev_position']
    @uuid = params['rev_response_id']
    @platform = params['platform'] || 0

    impression_hash = params['rev_impression_hash']

    track_impression(impression_hash)
    track_view
  rescue HTTP::Error, HTTP::TimeoutError, HTTP::ConnectionError, StandardError => e
    store_failed_impression
    Rails.logger.info("Ads error impressions request:  #{e}")
    export_prometheus_metric('fail')
  end

  def track_view
    view_hash = Redis.current.get("ads:revcontent:view:#{@uuid}") || ''
    full_url = "#{@parsed_url.site}/#{VIEWS_PATH}"
    request_data = { 'view' => view_hash, 'view_type' => 'widget', 'p[]' => @position }
    response = HTTP.headers('Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8').timeout(2).post(full_url, form: request_data)
    store_view_response(response.code)
    export_prometheus_metric(response.code)
    if response.code != 200
      Rails.logger.info("Ads error views request. #{response.code}, #{@uuid}, #{@position}, #{view_hash.chars.first(5).join}, #{view_hash.chars.last(5).join} ")
    end
  end

  def track_impression(impression_hash)
    impression_hash = impression_hash.gsub(' ', '+') if @platform === 1
    impression_hash = CGI.escape(impression_hash)
    full_url = "#{@parsed_url.site}/#{IMPRESSIONS_PATH}?d=#{impression_hash}"
    response = HTTP.timeout(2).get(full_url)
    store_impression_response(response.code)
  end

  def store_view_response(response_code)
    today = Time.now.strftime('%Y-%m-%d')
    redis_key = "ads-views-#{@provider}-statuses-codes:#{today}"
    Redis.current.zincrby(redis_key, 1, response_code)
    Redis.current.expire(redis_key, 7.days.seconds)
  end

  def export_prometheus_metric(status)
    Prometheus::ApplicationExporter::increment(:ad_impressions, {status: status, provider: @provider})
  end
end
