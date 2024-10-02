# frozen_string_literal: true

class TrackRumbleAdImpressionsWorker
  include Sidekiq::Worker
  include Redisable
  include TrackAdImpressionsConcern

  sidekiq_options queue: 'ads', retry: 3

  API_URL = ENV.fetch('RUMBLE_ADS_URL', false)

  def perform(params)
    @provider = 'rumble'

    path = CGI.unescape(params['path']);
    parsed_url = Addressable::URI.parse(API_URL)
    full_url = "#{parsed_url.site}#{path}"

    response = HTTP.timeout(1).get(full_url)
    response_code = response.headers['Platform-Response-Code']

    store_impression_response(response_code)

    export_prometheus_metric(response_code)
  rescue HTTP::Error, HTTP::TimeoutError, HTTP::ConnectionError, StandardError => e
    store_failed_impression
    Rails.logger.info("Ads error impressions request:  #{e}, URL: #{full_url}")
    export_prometheus_metric('fail')
  end

  def export_prometheus_metric(status)
    status = 'success' if status.blank?
    Prometheus::ApplicationExporter::increment(:ad_impressions, {status: status, provider: @provider})
  end
end