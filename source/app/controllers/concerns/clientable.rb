# frozen_string_literal: true

module Clientable
  extend ActiveSupport::Concern

  included do
    after_action :log_android_activity, if: :log_android_activity?
  end

  def ios_client?
    request&.user_agent&.strip&.match(/^TruthSocial\/(\d+) .+/).to_s.present?
  end

  def android_client?
    request&.user_agent&.strip&.match(/^TruthSocialAndroid\/okhttp\//).to_s.present?
  end

  def log_android_activity
    DeviceVerification.create!(
      remote_ip: request.remote_ip,
      platform_id: 2,
      details: {
        user_id: current_user.id,
        token_id: doorkeeper_token.id,
        endpoint: "#{request.method} #{request.path}",
        assertion_header: request.headers['x-tru-assertion'] || 'Missing assertion header',
      }
    )
  end

  private

  def log_android_activity?
    false
  end
end
