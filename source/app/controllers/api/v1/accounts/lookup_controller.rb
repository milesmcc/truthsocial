# frozen_string_literal: true

class Api::V1::Accounts::LookupController < Api::BaseController
  before_action -> { authorize_if_got_token! :read, :'read:accounts' }
  before_action :set_account
  before_action :require_authenticated_user!, unless: :allowed_public_access?

  def show
    render json: @account, serializer: REST::AccountSerializer, tv_account_lookup: true
  end

  private

  def set_account
    @account = ResolveAccountService.new.call(params[:acct], skip_webfinger: true) || raise(ActiveRecord::RecordNotFound)
  end

  def allowed_public_access?
    current_user || (action_name == 'show' && @account&.user&.unauth_visibility?)
  end
end
