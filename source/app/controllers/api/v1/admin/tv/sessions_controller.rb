# frozen_string_literal: true

class Api::V1::Admin::Tv::SessionsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!
  before_action :authenticate_passed_user

  def index
    session_id = TvDeviceSession.find_by(oauth_access_token_id: @doorkeeper_token.id)&.tv_session_id
    tv_profile_id = TvAccount.find_by(account_id: @account_id)&.p_profile_id

    if session_id.present? && tv_profile_id.present?
      render json: { 'session_id': session_id, 'profile_id': tv_profile_id.to_s }
      return
    end

    if tv_profile_id.nil?
      TvAccountsCreateWorker.perform_async(@account_id, @doorkeeper_token.id)
    else
      TvAccountsLoginWorker.perform_async(@account_id, @doorkeeper_token.id)
    end

    not_found
  end

  private

  def authenticate_passed_user
    @doorkeeper_token = OauthAccessToken.where(token: params[:oauth_token]).where(revoked_at: nil).first
    if @doorkeeper_token.nil?
      render json: { error: 'Unauthorized user token' }, status: 403 and return
    end
    @account_id = User.find(@doorkeeper_token.resource_owner_id)&.account_id
  end
end
