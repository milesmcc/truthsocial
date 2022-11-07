# frozen_string_literal: true

class Scheduler::UsersApprovalScheduler
  include Sidekiq::Worker
  sidekiq_options retry: 0

  SCHEDULER_FREQUENCY = 5
  
  def perform
    return unless (limit_per_hour = ENV['USERS_PER_HOUR'].to_i) > 0
    approve_number = (limit_per_hour.to_f/60*SCHEDULER_FREQUENCY).ceil
    Admin::AccountBulkApprovalWorker.perform_async({reviewed_number: approve_number})
  end
end
