require 'prometheus_exporter/client'

module Prometheus
  module ApplicationExporter
    extend self

    @counter_instances = {}
    counter_metrics = {
      statuses: 'number of created statuses',
      retruths: 'number of retruths',
      replies: 'number of replies',
      favourites: 'number of favourites',
      reports: 'number of reports',
      blocks: 'number of blocks',
      login_attempts: 'number of login attempts',
      registrations: 'number of registrations',
      media_uploads: 'number of uploaded media files',
      follows: 'number of accounts following account',
      unfollows: 'number of accounts unfollowing accounts',
      links: 'number of posted links',
      approves: 'number of approved users'
    }

    prometheus_client = PrometheusExporter::Client.default

    counter_metrics.each do |key, value|
      @counter_instances[key] = prometheus_client.register(:counter, key, value)
    end

    def increment(metric, labels = {})
      return if Rails.env.test? || Rails.env.development?

      @counter_instances[metric]&.increment(labels) 
    end
  end
end