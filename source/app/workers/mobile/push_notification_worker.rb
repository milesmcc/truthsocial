# frozen_string_literal: true

class Mobile::PushNotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'push', retry: 5

  TTL     = 48.hours.to_s
  URGENCY = 'normal'

  def perform(subscription_id, notification_id)
    @subscription = Web::PushSubscription.find(subscription_id)
    @notification = Notification.find(notification_id)
    @endpoint     = ENV['MOBILE_NOTIFICATION_ENDPOINT']

    # Polymorphically associated activity could have been deleted
    # in the meantime, so we have to double-check before proceeding
    return unless @endpoint.present? && @notification.activity.present? && @subscription.pushable?(@notification)

    payload = push_notification_json

    request_pool.with(Addressable::URI.parse(@endpoint).normalized_site) do |http_client|
      request = Request.new(:post, @endpoint, body: payload, http_client: http_client)

      request.add_headers(
        'Content-Type' => 'application/octet-stream'
      )

      request.perform do |response|
        # If the server responds with an error in the 4xx range
        # that isn't about rate-limiting or timeouts, we can
        # assume that the subscription is invalid or expired
        # and must be removed

        if !(200...300).cover?(response.code)
          raise Mastodon::UnexpectedResponseError, response
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    true
  end

  private

  def push_notification_json
    json = I18n.with_locale(@subscription.locale || I18n.default_locale) do
      ActiveModelSerializers::SerializableResource.new(
        @notification,
        serializer: Mobile::NotificationSerializer,
        scope: @subscription,
        scope_name: :current_push_subscription
      ).as_json
    end

    notification_wrapper = { 'notifications' => [json] }.as_json

    Oj.dump(notification_wrapper)
  end

  def request_pool
    RequestPool.current
  end
end
