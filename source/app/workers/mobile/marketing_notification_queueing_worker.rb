# frozen_string_literal: true

class Mobile::MarketingNotificationQueueingWorker
  include LinksParserConcern
  include Sidekiq::Worker

  TTL     = 8.hours.to_s
  URGENCY = 'normal'

  def self.prepare_notifications(message:, url:)
    self.perform_async(message, url)
  end

  def perform(message, url)
    mark_id = nil
    if (status_id = extract_status_id(url))
      status = Status.find_by(id: status_id)
      if status
        mark_id = NotificationsMarketing.create(status: status, message: message).id
      end
    end

    Mobile::MarketingNotificationWorker.queue_notifications(message: message, url: url, mark_id: mark_id&.to_s)
  end
end
