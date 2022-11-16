# frozen_string_literal: true

class Admin::AccountBulkApprovalWorker
  include Sidekiq::Worker

  def perform(options = {})
    AccountBulkApprovalService.new.call(options)
  end
end
