# frozen_string_literal: true

class Api::V1::Truth::Admin::AccountsController < Api::BaseController
  include EmailHelper

  before_action :require_staff!
  before_action -> { doorkeeper_authorize! :'admin:read', :'admin:read:accounts' }, only: [:index, :blacklist, :count, :email_domain_blocks]
  before_action -> { doorkeeper_authorize! :'admin:write', :'admin:write:accounts' }, only: [:update, :confirm_totp]
  before_action :set_account, only: [:update, :confirm_totp]
  before_action :set_email_domain_block, only: :email_domain_blocks

  def index
    @accounts = account_search
    render json: Panko::ArraySerializer.new(
      @accounts,
      each_serializer: REST::V2::Admin::AccountSerializer,
      context: {
        advertisers: Account.recent_advertisers(@accounts.pluck(:id)),
      }
    ).to_json
  end

  def update
    if params[:password].present?
      update_users_password
    elsif params[:email]
      set_new_email
    else
      update_account
    end
  end

  def blacklist
    render json: { blacklist: suspended_accounts_exist? }, status: 200
  end

  def count
    render json: { count: number_of_accounts }, status: 200
  end

  def email_domain_blocks
    render json: { disposable: !!@email_domain_block.disposable }, status: 200
  end

  def confirm_totp
    unless @account.user.validate_and_consume_otp!(totp_params[:code])
      render json: {
        error_code: 'OTP_CODE_INVALID',
        error_message: I18n.t('otp_authentication.invalid_code'),
      }, status: 422
    end
  end

  private

  def account_search
    oauth_token = params[:oauth_token]
    if oauth_token.present?
      find_by_token(oauth_token)
    else
      AdminAccountSearchService.new.call(
        params[:query],
        current_account,
        limit: limit_param(DEFAULT_ACCOUNTS_LIMIT)
      )
    end
  end

  def suspended_accounts_exist?
    if Account.joins(:user).where.not(suspended_at: nil).where(user: { sms: blacklist_params[:sms] }).exists?
      1
    else
      0
    end
  end

  def number_of_accounts
    if (email = count_params[:email])
      count_by_email(email)
    elsif count_params[:sms].present?
      # For admin users, allow unlimited accounts
      if User.where(admin: true).where(sms: count_params[:sms]).exists?
        0
      else
        User.where(sms: count_params[:sms]).size
      end
    else
      0
    end
  end

  def count_by_email(email)
    User.find_by(email: email).present? || CanonicalEmailBlock.block?(email) || UserBaseEmail.find_by(email: email_to_canonical_email(email)).present? ? 1 : 0
  end

  def blacklist_params
    params.permit(:sms)
  end

  def count_params
    params.permit(:email, :sms)
  end

  def account_params
    params.require(:account).permit(:username, :display_name, :note, :website)
  end

  def set_account
    account_id = params[:account_id] || params[:id]
    @account = Account.find(account_id)
  end

  def set_new_email
    new_email = params[:email]

    if new_email != @account.user.email
      @account.user.skip_reconfirmation!
      @account.user.update!(email: new_email)
    end

    render json: { status: :success }
  end

  def set_email_domain_block
    @email_domain_block = EmailDomainBlock.find_by!(domain: params.require(:domain))
  end

  def update_users_password
    @account.user.skip_password_change_notification!

    if @account.user.reset_password(params[:password], params[:password])
      OauthAccessToken.where(resource_owner_id: @account.user.id).delete_all
      @account.user.session_activations.destroy_all
      @account.user.forget_me!
      render json: { status: :success }, status: 200
    end
  end

  def update_account
    if @account.update(account_params)
      render json: { status: :success }, status: 200
    else
      render json: @account.errors, status: :unprocessable_entity
    end
  end

  def find_by_token(oauth_token)
    doorkeeper_token = OauthAccessToken.find_by!(token: oauth_token, revoked_at: nil)
    [User.find(doorkeeper_token&.resource_owner_id)&.account]
  end

  def totp_params
    params.permit(:code)
  end
end
