# frozen_string_literal: true

class Api::V1::Accounts::CredentialsController < Api::BaseController
  include JwtConcern
  include Clientable

  TV_REQUIRED_IOS_VERSION = ENV.fetch('TV_REQUIRED_IOS_VERSION', 0).to_i
  TV_REQUIRED_ANDROID_VERSION = ENV.fetch('TV_REQUIRED_ANDROID_VERSION', 0).to_i

  before_action -> { doorkeeper_authorize! :read, :'read:accounts', :ads }, except: [:update]
  before_action -> { doorkeeper_authorize! :write, :'write:accounts' }, only: [:update]

  skip_before_action :require_functional!, only: [:show]
  before_action :require_user!, only: [:update, :chat_token]
  before_action :set_account, only: [:update, :chat_token, :show]
  before_action :verify_credentials_require_user!, only: [:show]
  before_action :enable_feature_flag, only: [:show]
  before_action :create_tv_user, only: [:show]

  def show
    render json: @account, serializer: REST::CredentialAccountSerializer, access_token: doorkeeper_token, android_client: android_client?, tv_account_lookup: true
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
    current_user.update!(unauth_visibility_params) if unauth_visibility_params
    ActivityPub::UpdateDistributionWorker.perform_async(@account.id)
    render json: @account, serializer: REST::CredentialAccountSerializer
  end

  private

  def account_params
    # Pleroma compatibility
    params[:accepting_messages] = params[:accepting_messages] || accepts_chats_messages || !!@account.accepting_messages
    params[:feeds_onboarded] = truthy_param?(:feeds_onboarded) if params[:feeds_onboarded]
    params[:tv_onboarded] = truthy_param?(:tv_onboarded) if params[:tv_onboarded]
    params[:show_nonmember_group_statuses] = truthy_param?(:show_nonmember_group_statuses) if params[:show_nonmember_group_statuses]
    params[:receive_only_follow_mentions] = truthy_param?(:receive_only_follow_mentions) if params[:receive_only_follow_mentions]

    params.permit(:display_name,
                  :location,
                  :website,
                  :note,
                  :avatar,
                  :header,
                  :locked,
                  :discoverable,
                  :accepting_messages,
                  :chats_onboarded,
                  :feeds_onboarded,
                  :tv_onboarded,
                  :show_nonmember_group_statuses,
                  :receive_only_follow_mentions,
                  pleroma_settings_store: {},
                  fields_attributes: [:name, :value]
    )
  end

  def accepts_chats_messages
    params[:accepts_chat_messages].to_s.empty? ? false : params[:accepts_chat_messages].to_s
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

  def unauth_visibility_params
    params.permit(:unauth_visibility)
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

  def create_tv_user
    return if invalid_ios_version? && !current_account.tv_enabled?

    session_id = TvDeviceSession.find_by(oauth_access_token_id: doorkeeper_token.id)&.tv_session_id
    tv_profile_id = TvAccount.find_by(account_id: current_account.id)&.p_profile_id

    return if session_id.present? && tv_profile_id.present?

    if tv_profile_id.nil?
      TvAccountsCreateWorker.perform_async(current_account.id, doorkeeper_token.id)
    else
      TvAccountsLoginWorker.perform_async(current_account.id, doorkeeper_token.id)
    end
  end

  def enable_feature_flag
    return unless required_android_version
    ::Configuration::AccountEnabledFeature.upsert(
      account_id: current_account.id,
      feature_flag_id: 1,
    )
  end

  def invalid_ios_version?
    ios_version = request&.user_agent&.strip&.match(/^TruthSocial\/(\d+) .+/) || []
    ios_version[1].nil? || TV_REQUIRED_IOS_VERSION.zero? || ios_version[1].to_i < TV_REQUIRED_IOS_VERSION
  end

  def required_android_version
    android_version = request&.user_agent&.strip&.match(/^TruthSocialAndroid\/okhttp\/.+\/(\d+)/) || []
    !android_version[1].nil? && !TV_REQUIRED_ANDROID_VERSION.zero? && android_version[1].to_i == TV_REQUIRED_ANDROID_VERSION
  end
end
