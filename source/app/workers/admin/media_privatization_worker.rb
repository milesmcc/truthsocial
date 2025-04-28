# frozen_string_literal: true

class Admin::MediaPrivatizationWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'pull'

  def perform(account_id)
    PrivatizeMediaAttachmentService.new.call(Account.find(account_id))
  rescue ActiveRecord::RecordNotFound
    true
  end
end
