# frozen_string_literal: true

class StatusModeratedEventWorker
  include Sidekiq::Worker
  QUEUE = ENV.fetch('CURRENT_DC', 'shared')

  sidekiq_options queue: QUEUE, retry: 5

  def perform(account_id, status_id, decision, moderation_source = 'AUTOMOD', spam_score = 0)
    Events::StatusModeratedEvent.new(account_id, status_id, decision, moderation_source, spam_score).handle
  end
end
