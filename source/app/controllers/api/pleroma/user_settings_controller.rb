# frozen_string_literal: true
class Api::Pleroma::UserSettingsController < Api::BaseController
  before_action :require_user!
  before_action :validate_password
  before_action :validate_email, only: :change_email
  before_action :set_new_email, only: :change_email

  def change_password
    if current_user.reset_password(resource_params[:new_password], resource_params[:new_password_confirmation])
      render json: { status: :success }
    else
      render json: { error: 'Password and password confirmation do not match.' }, status: 400
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
    AccountDeletionWorker.perform_async(current_user.account_id)
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
