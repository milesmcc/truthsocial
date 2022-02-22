# Temporary class to relieve pressure off of FeedInsertWorker as we migrate to Bailey
class NotifyServiceWorker
  include Sidekiq::Worker

  def perform(recipient, type, activity)
    NotifyService.call(recipient, type, activity)
  end
end
