# frozen_string_literal: true
class Api::Pleroma::AccountsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }, only: [:mfa, :setup_totp, :backup_codes]
  before_action -> { doorkeeper_authorize! :write }, only: [:confirm_totp, :delete_totp]
  before_action :require_user!
  before_action :prepare_two_factor, only: [:setup_totp]
  before_action :validate_password, only: [:confirm_totp, :delete_totp]

  def mfa
    otp_enabled = current_user.otp_required_for_login

    render json: { settings: { enabled: otp_enabled, totp: otp_enabled } }
  end

  def setup_totp
    render json: { "key": @new_otp_secret, "provisioning_uri": @provision_uri }
  end

  def confirm_totp
    if current_user.validate_and_consume_otp!(resource_params[:code])
      current_user.otp_required_for_login = true
      current_user.save!

      UserMailer.two_factor_enabled(current_user).deliver_later!
    else
      render json: {"error": I18n.t('otp_authentication.wrong_code')}, status: 422
    end
  end

  def backup_codes
    @recovery_codes = current_user.generate_otp_backup_codes!

    if current_user.save!
      render json: { "codes": @recovery_codes }
    else
      render json: current_user.errors, status: 422
    end
  end

  def delete_totp
    current_user.otp_required_for_login = false
    current_user.otp_secret = nil
    current_user.save!
  end

  private

  def prepare_two_factor
    @new_otp_secret = User.generate_otp_secret(32)
    @provision_uri = current_user.otp_provisioning_uri(current_user.email,
                                                       otp_secret: @new_otp_secret,
                                                       issuer: Rails.configuration.x.local_domain)
    current_user.otp_secret = @new_otp_secret
    current_user.save!
  end

  def validate_password
    forbidden unless current_user.valid_password?(resource_params[:password])
  end

  def resource_params
    params.permit(:password, :code)
  end
end
