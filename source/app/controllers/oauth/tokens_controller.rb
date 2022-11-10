# frozen_string_literal: true

class Oauth::TokensController < Doorkeeper::TokensController
  before_action :set_user, only: [:create]
  before_action :validate_password, only: [:create]

  def create
    if @user.present? && @user.otp_required_for_login?
      render json: {
        error: "mfa_required",
        supported_challenge_types: "totp",
        mfa_token: @user.user_token
      }, status: 403
    else
      super
    end
  end

  def revoke
    unsubscribe_for_token if token && authorized? && token.accessible?
    super
  end

  private

  def unsubscribe_for_token
    Web::PushSubscription.where(access_token_id: token.id).delete_all
  end

  def validate_password
    return unless @user.present?

    forbidden unless @user.valid_password?(params[:password])
  end

  def set_user
    @user = User.find_by(email: params[:username]) || Account.ci_find_by_username(params[:username])&.user
  end

  def forbidden
    code = 403
    render json: { error: Rack::Utils::HTTP_STATUS_CODES[code] }, status: code
  end
end
