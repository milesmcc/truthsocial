# frozen_string_literal: true

class Mobile::MarketingNotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'push', retry: 5

  TTL     = 8.hours.to_s
  URGENCY = 'normal'

  def self.queue_notifications(user_ids:, message:, url:)
    self.push_bulk(user_ids) do |user_id|
      [user_id, message, url]
    end
  end

  def perform(user_id, message, url)
    subscriptions = Web::PushSubscription.where(user_id: user_id)
    endpoint      = ENV.fetch('MOBILE_NOTIFICATION_ENDPOINT')

    # return unless endpoint.present? && subscriptions.any? && message && url

    subscriptions.each do |subscription|
      payload = push_notification_json(subscription.device_token, message, url)
      request_pool.with(Addressable::URI.parse(endpoint).normalized_site) do |http_client|
        request = Request.new(:post, endpoint, body: payload, http_client: http_client)

        request.add_headers(
          'Content-Type' => 'application/octet-stream'
        )

        request.perform do |response|
          # If the server responds with an error in the 4xx range
          # that isn't about rate-limiting or timeouts, we can
          # assume that the subscription is invalid or expired
          # and must be removed

          if (400..499).cover?(response.code) && ![408, 429].include?(response.code)
            subscription.destroy!
          elsif !(200...300).cover?(response.code)
            raise Mastodon::UnexpectedResponseError, response
          end
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    true
  end

  private

  def push_notification_json(token, message, url)
    { 'notifications' => [{token: [token], category: 'invite', platform: 1, message: message, extend: [{key: 'truthLink', val: url}]}] }.to_json
  end

  def request_pool
    RequestPool.current
  end
end
