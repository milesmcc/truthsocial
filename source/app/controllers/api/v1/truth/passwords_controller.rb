# frozen_string_literal: true
class Api::V1::Truth::PasswordsController < Api::BaseController
  skip_before_action :require_authenticated_user!

  before_action :set_confirm_user, only: :reset_confirm
  before_action :set_request_user, only: :reset_request
  before_action :validate_user_is_present, only: :reset_confirm
  around_action :set_locale, only: :reset_confirm

  def reset_confirm
    if @user.reset_password(password_reset_confirm_params[:password], password_reset_confirm_params[:password])
      update_users_password
      render json: { status: :success }
    else
      errors = @user.errors.to_hash
      password_invalid = errors[:password]&.pop
      default_error = I18n.t('users.password_mismatch', locale: :en)
      message, message_with_locale, code =
        if password_invalid.present?
          error = errors[:base]&.pop || default_error
          [error, password_invalid, 'PASSWORD_INVALID']
        else
          [default_error, I18n.t('users.password_mismatch'), 'PASSWORD_MISMATCH']
        end

      render json: {
        error: message,
        error_code: code,
        error_message: message_with_locale,
      }, status: 400
    end
  end

  def reset_request
    send_reset_password_instructions
  end

  private

  def validate_user_is_present
    forbidden if @user.blank?
  end

  def update_users_password
    @user.session_activations.destroy_all
    @user.forget_me!
  end

  def set_confirm_user
    @user = User.with_reset_password_token(password_reset_confirm_params[:reset_password_token])
  end

  def set_request_user
    email    = password_reset_request_params[:email]
    username = password_reset_request_params[:username]

    @user = if email.present?
              User.find_by(email: password_reset_request_params[:email])
            elsif username.present?
              Account.ci_find_by_username(username)&.user
            end
  end

  def send_reset_password_instructions
    @user.send_reset_password_instructions if @user.present?
  end

  def password_reset_confirm_params
    params.permit(:password, :reset_password_token)
  end

  def password_reset_request_params
    params.permit(:email, :username, :sms)
  end
end
