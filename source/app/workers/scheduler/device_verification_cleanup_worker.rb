# frozen_string_literal: true

class Scheduler::DeviceVerificationCleanupWorker
  include Sidekiq::Worker

  sidekiq_options retry: 0

  def perform
    idle_device_verifications.delete_all
  end

  private

  def idle_device_verifications
    DeviceVerification.where('created_at < ?', 6.months.ago)
  end
end
