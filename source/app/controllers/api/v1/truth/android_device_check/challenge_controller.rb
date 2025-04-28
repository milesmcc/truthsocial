# frozen_string_literal: true

class Api::V1::Truth::AndroidDeviceCheck::ChallengeController < Api::BaseController
  before_action -> { doorkeeper_authorize! :write }
  before_action :require_user!

  def create
    challenge = AndroidDeviceCheck::OneTimeChallengeService.new(user: current_user).call

    render json: { challenge: challenge }
  end
end
