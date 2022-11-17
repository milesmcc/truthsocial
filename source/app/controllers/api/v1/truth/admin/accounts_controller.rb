# frozen_string_literal: true

class Api::V1::Truth::Admin::AccountsController < Api::BaseController
  before_action :require_staff!
  before_action -> { doorkeeper_authorize! :'admin:read', :'admin:read:accounts' }, only: [:count, :update]
  before_action :set_account, only: [:update]

  def index
    accounts = Account.includes(:account_stat, :user).ransack(params[:query])
    accounts.sorts = params[:sorts] || "id desc"
    accounts = accounts.result.page(params[:page])
    render json: accounts, each_serializer: REST::Admin::AccountSerializer
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

  def count
    render json: { count: number_of_accounts }, status: 200
  end

  private

  def number_of_accounts
    if count_params[:email].present?
      User.find_by(email: count_params[:email]).present? ? 1 : 0
    elsif count_params[:sms].present?
      User.where(sms: count_params[:sms]).size
    else
      0
    end
  end

  def count_params
    params.permit(:email, :sms)
  end

  def account_params
    params.require(:account).permit(:username, :display_name, :note)
  end

  def set_account
    @account = Account.find(params[:id])
  end

  def set_new_email
    new_email = params[:email]

    if new_email != @account.user.email
      @account.user.skip_reconfirmation!
      @account.user.update!(email: new_email)
    end

    render json: { status: :success }
  end

  # TODO: Vlad to refactor share access-token removal
  def update_users_password
    @account.user.skip_password_change_notification!

    if @account.user.reset_password(params[:password], params[:password])
      Doorkeeper::AccessToken.where(resource_owner_id: @account.user.id).delete_all
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
end