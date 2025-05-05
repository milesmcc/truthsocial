# frozen_string_literal: true

class Api::V1::Truth::IosDeviceCheck::ChallengeController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :read }
  before_action :require_user!

  def index
    challenge = IosDeviceCheck::OneTimeChallengeService.new(user: current_user, object_type: params['object_type']).call

    render json: { challenge: challenge }, status: 200
  end
end
