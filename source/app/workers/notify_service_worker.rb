# Temporary class to relieve pressure off of FeedInsertWorker as we migrate to Bailey
class NotifyServiceWorker
  include Sidekiq::Worker

  def perform(account_id, type, status_id)
    NotifyService.new.call(Account.find(account_id), type, Status.find(status_id))
  end
end
