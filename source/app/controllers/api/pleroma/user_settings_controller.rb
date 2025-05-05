# frozen_string_literal: true
class Api::Pleroma::UserSettingsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :write }
  before_action :require_user!
  before_action :validate_password
  before_action :validate_email, only: :change_email
  before_action :set_new_email, only: :change_email
  around_action :set_locale, only: :change_password

  def change_password
    if current_user.reset_password(resource_params[:new_password], resource_params[:new_password_confirmation])
      OauthAccessToken.where.not(token: doorkeeper_token.token).where(resource_owner_id: current_user.id).update_all(revoked_at: Time.now.utc)

      render json: { status: :success }
    else
      errors = current_user.errors.to_hash
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

  def change_email
    render json: { status: :success }
  end

  def delete_account
    destroy_account!
    render json: { status: :success }
  end

  private

  def set_new_email
    new_email = resource_params[:email]

    if new_email != current_user.email
      current_user.update!(
        unconfirmed_email: new_email,
        # Regenerate the confirmation token:
        confirmation_token: nil
      )

      current_user.send_confirmation_instructions
    end
  end

  def destroy_account!
    current_account.suspend!(origin: :local)
    account_id = current_user.account_id
    AccountDeletionWorker.perform_async(
      account_id,
      account_id,
      deletion_type: 'self_deletion',
      skip_activitypub: true,
    )
    sign_out
  end

  def validate_email
    return forbidden if resource_params[:email].blank?

    forbidden if User.find_by(email: resource_params[:email].downcase).present?
  end

  def validate_password
    forbidden unless current_user.valid_password?(resource_params[:password])
  end

  def resource_params
    params.permit(:password, :new_password, :new_password_confirmation, :email)
  end
end
