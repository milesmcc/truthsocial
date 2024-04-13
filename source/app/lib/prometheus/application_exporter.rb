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
      approves: 'number of approved users',
      ad_impressions: 'number of ad impressions',
      chats: 'number of chats',
      chat_messages: 'number of chat messages',
    }

    @histogram_instances = {}
    histogram_metrics = {
      video_passthrough_encoding: 'duration for processing passthrough video encoding',
    }

    prometheus_client = PrometheusExporter::Client.default

    counter_metrics.each do |key, value|
      @counter_instances[key] = prometheus_client.register(:counter, key, value)
    end

    histogram_metrics.each do |key, value|
      @histogram_instances[key] = prometheus_client.register(:histogram, key, value)
    end

    def increment(metric, labels = {})
      return if Rails.env.test? || Rails.env.development?

      @counter_instances[metric]&.increment(labels)
    end

    def observe_duration(metric, duration, labels = {})
      return if Rails.env.test? || Rails.env.development?

      @histogram_instances[metric]&.observe(duration, labels)
    end
  end
end
