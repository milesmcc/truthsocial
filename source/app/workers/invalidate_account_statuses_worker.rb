# frozen_string_literal: true

class InvalidateAccountStatusesWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull', lock: :until_executed

  def perform(account_id)
    account = Account.find(account_id)
    status_ids = account.statuses.pluck(:id)
    reblog_ids = Status.where(reblog_of_id: status_ids).pluck(:id)
    quote_ids = Status.where(quote_id: status_ids).pluck(:id)

    (status_ids + reblog_ids + quote_ids).each do |id|
      Rails.cache.delete("statuses/#{id}")
      InvalidateSecondaryCacheService.new.call("InvalidateStatusCacheWorker", id)
    end

  rescue ActiveRecord::RecordNotFound
    true
  end
end
