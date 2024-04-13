# frozen_string_literal: true

class Oauth::MfaController < Doorkeeper::TokensController
  before_action :check_challenge_type

  def challenge
    params[:grant_type] = "password"
    request.params[:username] = false
    create
  end

  private

  def check_challenge_type
    forbidden unless challenge_params[:challenge_type] == "totp"
  end

  def challenge_params
    params.permit(:client_id, :client_secret, :mfa_token, :code, :challenge_type, :redirect_uri)
  end

  def forbidden
    code = 403
    render json: { error: Rack::Utils::HTTP_STATUS_CODES[code] }, status: code
  end
end
