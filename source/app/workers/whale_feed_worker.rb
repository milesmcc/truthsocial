# frozen_string_literal: true

class WhaleFeedWorker
  include Sidekiq::Worker

  def perform(status_id)
    FeedManager.instance.push_to_whale(Status.find(status_id))
  rescue ActiveRecord::RecordNotFound
    true
  end
end
