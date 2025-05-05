# frozen_string_literal: true

class LinkCrawlWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', retry: 5

  def perform(status_id, url = nil, domain = nil)
    FetchLinkCardService.new.call(Status.find(status_id), url, domain)
  rescue ActiveRecord::RecordNotFound
    true
  end
end
