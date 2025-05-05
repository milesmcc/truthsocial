# frozen_string_literal: true

class InspectLinkWorker
  include Sidekiq::Worker
  QUEUE = ENV.fetch('CURRENT_DC', 'shared')

  sidekiq_options lock: :until_executed, retry: 2

  def perform(link_id, account_id = nil)
    InspectLinkService.new.call(Link.find(link_id), account_id)
  rescue ActiveRecord::RecordNotFound
    true
  end

  def self.perform_if_needed(link, account_id = nil)
    return if link.status == 'whitelisted'
    self.set(queue: QUEUE).perform_async(link.id, account_id) if link.last_visited_at.nil? || link.last_visited_at < 60.minutes.ago
  end
end
