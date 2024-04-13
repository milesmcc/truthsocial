# frozen_string_literal: true

class Mobile::ChannelNotificationQueueingWorker
  include Sidekiq::Worker

  TTL     = 8.hours.to_s
  URGENCY = 'normal'

  def self.prepare_notifications(message_id:)
    self.perform_async(message_id)
  end

  def perform(message_id)
    message = ChatMessage.find(message_id)
    Mobile::ChannelNotificationWorker.queue_notifications(message: message)
  end
end
