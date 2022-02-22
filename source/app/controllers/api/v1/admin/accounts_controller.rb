# frozen_string_literal: true

class Api::V1::Admin::AccountsController < Api::BaseController
  include Authorization
  include AccountableConcern

  LIMIT = 100

  before_action -> { doorkeeper_authorize! :'admin:read', :'admin:read:accounts' }, only: [:index, :show]
  before_action -> { doorkeeper_authorize! :'admin:write', :'admin:write:accounts' }, except: [:index, :show]
  before_action :require_staff!
  before_action :set_accounts, only: :index
  before_action :set_account, except: [:index, :create, :bulk_approve]
  before_action :require_local_account!, only: [:enable, :approve, :reject]

  after_action :insert_pagination_headers, only: :index

  FILTER_PARAMS = %i(
    local
    remote
    by_domain
    active
    pending
    disabled
    sensitized
    silenced
    suspended
    username
    display_name
    email
    ip
    staff
    sms
  ).freeze

  PAGINATION_PARAMS = (%i(limit) + FILTER_PARAMS).freeze

  def index
    authorize :account, :index?
    render json: @accounts, each_serializer: REST::Admin::AccountSerializer
  end

  def show
    authorize @account, :show?
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def create
    account = Account.new(username: params[:username])

    user = User.new(
      email: params[:email],
      password: params[:password],
      sms: params[:sms],
      agreement: true,
      admin: params[:role] == 'admin',
      approved: ['true', true].include?(params[:approved]),
      moderator: params[:role] == 'moderator',
      confirmed_at: params[:confirmed] ? Time.now.utc : nil,
      bypass_invite_request_check: true
    )

    user.account = account
    account.verify! if ['true', true].include?(params[:verified])
    user.set_waitlist_position unless params[:approved]

    if user.save
      send_registration_email(user)
      export_prometheus_metric
      render json: user.account, serializer: REST::Admin::AccountCreateSerializer
    else
      render json: { errors: user.errors.to_h }, status: 422
    end
  end

  def role
    authorize @account.user, :update?
    @account.user.update(role: params[:role])
    log_action :update_role, @account.user
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def enable
    authorize @account.user, :enable?
    @account.user.enable!
    log_action :enable, @account.user
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def approve
    authorize @account.user, :approve?
    @account.user.approve!
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def bulk_approve
    if bulk_approve_params[:number].present? || bulk_approve_params[:all].present?
      opts = {}
      opts[:number] = bulk_approve_params[:number].to_i if bulk_approve_params[:number].present?
      opts[:all] = ActiveModel::Type::Boolean.new.cast(bulk_approve_params[:all]) if bulk_approve_params[:all].present?
      Admin::AccountBulkApprovalWorker.perform_async(opts)
      render json: {}, status: 204
    else
      render json: { error: 'You must include either a number or all param' }, status: 400
    end
  end

  def reject
    authorize @account.user, :reject?
    DeleteAccountService.new.call(@account, reserve_email: false, reserve_username: false)
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def destroy
    authorize @account, :destroy?
    Admin::AccountDeletionWorker.perform_async(@account.id)
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def unsensitive
    authorize @account, :unsensitive?
    @account.unsensitize!
    log_action :unsensitive, @account
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def unsilence
    authorize @account, :unsilence?
    @account.unsilence!
    log_action :unsilence, @account
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def unsuspend
    authorize @account, :unsuspend?
    @account.unsuspend!
    Admin::UnsuspensionWorker.perform_async(@account.id)
    log_action :unsuspend, @account
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def unverify
    authorize @account, :unverify?
    @account.unverify!
    log_action :unverify, @account
    redirect_to admin_account_path(@account.id), notice: I18n.t('admin.accounts.unverified_msg', username: @account.acct)
  end

  private

  def set_accounts
    @accounts = filtered_accounts.order(id: :desc).includes(user: [:invite_request, :invite]).to_a_paginated_by_id(limit_param(LIMIT), params_slice(:max_id, :since_id, :min_id))
  end

  def set_account
    @account = Account.find(params[:id])
  end

  def filtered_accounts
    AccountFilter.new(filter_params).results
  end

  def filter_params
    params.permit(*FILTER_PARAMS)
  end

  def bulk_approve_params
    params.permit(:number, :all)
  end

  def insert_pagination_headers
    set_pagination_headers(next_path, prev_path)
  end

  def next_path
    api_v1_admin_accounts_url(pagination_params(max_id: pagination_max_id)) if records_continue?
  end

  def prev_path
    api_v1_admin_accounts_url(pagination_params(min_id: pagination_since_id)) unless @accounts.empty?
  end

  def pagination_max_id
    @accounts.last.id
  end

  def pagination_since_id
    @accounts.first.id
  end

  def records_continue?
    @accounts.size == limit_param(LIMIT)
  end

  def pagination_params(core_params)
    params.slice(*PAGINATION_PARAMS).permit(*PAGINATION_PARAMS).merge(core_params)
  end

  def require_local_account!
    forbidden unless @account.local? && @account.user.present?
  end

  def export_prometheus_metric
    Prometheus::ApplicationExporter::increment(:registrations)
  end

  def send_registration_email(user)
    if user.approved?
      NotificationMailer.user_approved(user.account).deliver_later
    else
      UserMailer.waitlisted(user).deliver_later
    end
  end
end
