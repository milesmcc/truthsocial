# frozen_string_literal: true

class Scheduler::DoorkeeperCleanupScheduler
  include Sidekiq::Worker

  sidekiq_options retry: 0

  def perform
    OauthAccessToken.where('revoked_at IS NOT NULL').where('revoked_at < NOW()').delete_all
    Doorkeeper::AccessGrant.where('revoked_at IS NOT NULL').where('revoked_at < NOW()').delete_all
    SystemKey.expired.delete_all
  end
end
