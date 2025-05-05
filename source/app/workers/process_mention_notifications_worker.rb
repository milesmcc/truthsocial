# frozen_string_literal: true

class ProcessMentionNotificationsWorker
  include Sidekiq::Worker

  def perform(status_id, mention_id, type)
    status = Status.find(status_id)

    account = Account.find(status.account.id)
    return if account.suspended?

    mention = Mention.find(mention_id)
    LocalNotificationWorker.perform_async(mention.account.id, mention.id, mention.class.name, type.to_sym)
  rescue ActiveRecord::RecordNotFound
    true
  end
end
