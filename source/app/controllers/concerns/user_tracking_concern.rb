# frozen_string_literal: true

module UserTrackingConcern
  include Redisable

  extend ActiveSupport::Concern
  TRACKED_CONTROLLERS = %w(credentials)
  INTERACTIONS_SCORE_TRACKED_CONTROLLER = 'credentials'

  included do
    before_action :update_user_sign_in
  end

  private

  def update_user_sign_in
    if user_needs_sign_in_update?
      current_user.update_sign_in!(request)
      update_account_score
    end
  end

  def user_needs_sign_in_update?
    TRACKED_CONTROLLERS.include?(controller_name) && user_signed_in? && (current_user.current_sign_in_at.nil? || current_user.current_sign_in_at < Date.today)
  end

  def update_account_score
    return unless controller_name == INTERACTIONS_SCORE_TRACKED_CONTROLLER && current_account

    current_week = Time.now.strftime('%U').to_i
    last_week = current_week - 1
    key1 = "interactions_score:#{current_account.id}:#{current_week}"
    key2 = "interactions_score:#{current_account.id}:#{last_week}"

    scores = Redis.current.mget(key1, key2)
    scores_sum = scores.compact.map(&:to_i).sum.to_i

    current_account.update(interactions_score: scores_sum) if scores_sum
  end
end
