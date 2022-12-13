# frozen_string_literal: true

module NotifyConcern
  extend ActiveSupport::Concern
  NOTIFICATION_INTERVALS = [0.5.minutes.seconds.to_i, 10.minutes.seconds.to_i]

  def current_interval(base_key)
    (redis.get("#{base_key}:current_interval").presence || NOTIFICATION_INTERVALS[0]).to_i
  end

  def base_key(recipient_account_id, type, status_id)
    status_id = '' if status_id.nil?
    "gn:#{recipient_account_id}:#{type}:#{status_id}" # gn = grouped notifications
  end

  def push_notification!(notification, recipient)
    return if notification.activity.nil?

    Redis.current.publish("timeline:#{recipient.id}", Oj.dump(event: :notification, payload: InlineRenderer.render(notification, recipient, :notification)))
    send_push_notifications!(notification, recipient)
  end

  def send_push_notifications!(notification, recipient)
    subscriptions = ::Web::PushSubscription.where(user_id: recipient.user.id)
                                           .select { |subscription| subscription.pushable?(notification) }

    web_subscription_ids = []
    mobile_subscription_ids = []

    subscriptions.each do |sub|
      if [1, 2].include?(sub.platform)
        mobile_subscription_ids << sub.id
      else
        web_subscription_ids << sub.id
      end
    end

    if web_subscription_ids.any?
      ::Web::PushNotificationWorker.push_bulk(web_subscription_ids) do |subscription_id|
        [subscription_id, notification.id]
      end
    end

    if mobile_subscription_ids.any?
      ::Mobile::PushNotificationWorker.push_bulk(mobile_subscription_ids) do |subscription_id|
        [subscription_id, notification.id]
      end
    end
  end
end
