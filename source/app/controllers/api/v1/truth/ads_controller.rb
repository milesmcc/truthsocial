# frozen_string_literal: true

class Api::V1::Truth::AdsController < Api::BaseController
  skip_before_action :require_authenticated_user!
  before_action -> { require_params(:device) }, only: [:index]

  def index
    render json: AdsService.new.call(params[:device]&.to_sym, request)
  end

  def impression
    AdsService.track_impression(params, request)
    render json: { status: :success }
  end

  def require_params(required_parm)
    params.require(required_parm)
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message.split(/\n/, 2).first }, status: 422
  end
end
