# frozen_string_literal: true

class Api::V1::Accounts::CredentialsController < Api::BaseController
  include JwtConcern

  before_action -> { doorkeeper_authorize! :read, :'read:accounts' }, except: [:update]
  before_action -> { doorkeeper_authorize! :write, :'write:accounts' }, only: [:update]

  skip_before_action :require_functional!, only: [:show]
  before_action :require_user!, only: [:update, :chat_token]
  before_action :set_account, only: [:update, :chat_token, :show]
  before_action :verify_credentials_require_user!, only: [:show]

  def show
    render json: @account, serializer: REST::CredentialAccountSerializer
  end

  def chat_token
    payload = {
      sub: @account.username,
      exp: Time.new.next_month(1).to_i,
      iat: Time.now.to_i,
      nbf: Time.now.to_i,
    }
    jwt_token = encode_jwt(payload)
    render json: { token: jwt_token }
  end

  def update
    UpdateAccountService.new.call(@account, account_params, raise_error: true)
    UserSettingsDecorator.new(current_user).update(user_settings_params) if user_settings_params
    ActivityPub::UpdateDistributionWorker.perform_async(@account.id)
    render json: @account, serializer: REST::CredentialAccountSerializer
  end

  private

  def account_params
    params.permit(:display_name, :location, :website, :note, :avatar, :header, :locked, :discoverable, pleroma_settings_store: {}, fields_attributes: [:name, :value])
  end

  def set_account
    @account = current_account
  end

  def user_settings_params
    return nil if params[:source].blank?

    source_params = params.require(:source)

    {
      'setting_default_privacy' => source_params.fetch(:privacy, @account.user.setting_default_privacy),
      'setting_default_sensitive' => source_params.fetch(:sensitive, @account.user.setting_default_sensitive),
      'setting_default_language' => source_params.fetch(:language, @account.user.setting_default_language),
    }
  end

  def verify_credentials_require_user!
    if !current_user
      render json: { error: 'This method requires an authenticated user' }, status: 422
    elsif !current_user.confirmed?
      render json: { error: 'Your login is missing a confirmed e-mail address' }, status: 403
    elsif !current_user.approved?
      render json: @account, serializer: REST::CredentialAccountSerializer, status: 403
    elsif !current_user.functional?
      render json: { error: 'Your login is currently disabled' }, status: 403
    else
      update_user_sign_in
    end
  end
end
