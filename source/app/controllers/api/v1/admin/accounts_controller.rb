# frozen_string_literal: true

class Api::V1::Admin::AccountsController < Api::BaseController
  include Authorization
  include AccountableConcern

  LIMIT = 100

  before_action :set_log_level

  before_action -> { doorkeeper_authorize! :'admin:read', :'admin:read:accounts' }, only: [:index, :show]
  before_action -> { doorkeeper_authorize! :'admin:write', :'admin:write:accounts' }, except: [:index, :show]
  before_action :require_staff!
  before_action :set_accounts, only: :index
  before_action :set_account, except: [:index, :create, :bulk_approve]
  before_action :set_policy, only: :create
  before_action :require_local_account!, only: [:enable, :approve, :reject]
  before_action :set_geo, only: [:create]
  before_action :set_registrations, only: [:create], if: -> { params[:token].present? }

  after_action :insert_pagination_headers, only: :index
  after_action :registration_cleanup, only: :create, if: -> { @user.persisted? && @registration }
  after_action :revert_log_level

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

  GEO_PARAMS = %i(
    country_name
    country_code
    city_name
    region_code
    region_name
  ).freeze

  PAGINATION_PARAMS = (%i(limit) + FILTER_PARAMS).freeze

  def index
    authorize :account, :index?
    render json: Panko::ArraySerializer.new(
      @accounts,
      each_serializer: REST::V2::Admin::AccountSerializer,
      context: {
        advertisers: Account.recent_advertisers(@accounts.pluck(:id)),
      }
    ).to_json
  end

  def show
    authorize @account, :show?
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def update
    update_hash = update_params.to_h
    if !@account.user.not_ready_for_approval? && !@account.user.ready_by_csv_import?
      update_hash[:approved] = true
      export_prometheus_metric(:approves)
    end

    if @account.user.update!(update_hash)
      render json: @account, serializer: REST::Admin::AccountSerializer
    else
      user_errors = account.user.errors.to_h
      render json: { errors: user_errors }, status: 422
    end
  end

  def create
    Rails.logger.info("Sign-up logs: attempting to register: #{params[:email]}")

    account = Account.new(
      username: params[:username],
      discoverable: params[:role] != 'moderator',
      feeds_onboarded: true
    )

    @user = User.new(
      email: params[:email],
      password: params[:password],
      sms: params[:sms],
      agreement: true,
      admin: params[:role] == 'admin',
      approved: ['true', true].include?(params[:approved]),
      moderator: params[:role] == 'moderator',
      confirmed_at: params[:confirmed] ? Time.now.utc : nil,
      bypass_invite_request_check: true,
      policy: @policy,
      sign_up_city_id: @city,
      sign_up_country_id: @country,
      sign_up_ip: params[:sign_up_ip]
    )

    @user.account = account
    account.verify! if ['true', true].include?(params[:verified])
    @user.set_waitlist_position unless @user.approved

    if @user.save
      send_registration_email
      export_prometheus_metric(:registrations)
      dispatch_rmq_event(account, params)
      log_successful_attempt
      render json: @user.account, serializer: REST::Admin::AccountCreateSerializer
    else
      user_errors = @user.errors.to_h
      log_failed_attempt(user_errors)
      render json: { errors: user_errors }, status: 422
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
    DeleteAccountService.new.call(
      @account,
      @current_account.id,
      deletion_type: 'api_admin_reject',
      reserve_email: false,
      reserve_username: false,
      skip_activitypub: true,
    )
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def destroy
    authorize @account, :destroy?
    Admin::AccountDeletionWorker.perform_async(@account.id, @current_account.id)
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

  def verify
    authorize @account, :verify?
    @account.verify!
    log_action :verify, @account
    render json: @account, serializer: REST::Admin::AccountSerializer
  end

  def unverify
    authorize @account, :unverify?
    @account.unverify!
    log_action :unverify, @account
    render json: @account, serializer: REST::Admin::AccountSerializer
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

  def update_params
    params.permit(:sms)
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

  def export_prometheus_metric(metric_type)
    Prometheus::ApplicationExporter.increment(metric_type)
  end

  def send_registration_email
    if @user.approved?
      NotificationMailer.user_approved(@user.account).deliver_later
    else
      UserMailer.waitlisted(@user).deliver_later
    end
  end

  def set_policy
    @policy = Policy.last
  end

  def geo_params
    params.permit(*GEO_PARAMS)
  end

  def set_geo
    geo = GeoService.new(
      city_name: geo_params[:city_name],
      country_code: geo_params[:country_code],
      country_name: geo_params[:country_name],
      region_name: geo_params[:region_name],
      region_code: geo_params[:region_code]
    )

    @city = geo.city
    @country = geo.country
  end

  def set_log_level
    @current_log_level = Rails.logger.level
    Rails.logger.level = :debug
  end

  def revert_log_level
    Rails.logger.level = @current_log_level
  end

  def set_registrations
    @registration = Registration.find_by(token: params[:token])
    if @registration&.ios_device?
      @registration_credential = @registration.registration_webauthn_credential
      @credential = @registration_credential&.webauthn_credential
      credential_error = 'Webauthn Credential is already associated with an account'
      render json: { errors: credential_error }, status: 422 and return if @credential&.user.present?
    end
  end

  def registration_cleanup
    if @registration.ios_device?
      @credential&.update!(user: @user) # Do we want to fail loudly?
    else
      user_params = { user_id: @user.id }
      verification = DeviceVerification.find_by("details ->> 'registration_token' = '#{ActiveRecord::Base.sanitize_sql(@registration.token)}'")
      details = verification.details
      new_details = details.merge(user_params)
      verification.update(details: new_details)
    end

    registration_otc = @registration.registration_one_time_challenge
    otc = registration_otc.one_time_challenge
    otc.destroy # This will also cascade delete the RegistrationOneTimeChallenge record.
    @registration.destroy
  end

  def dispatch_rmq_event(account, params)
    EventProvider::EventProvider.new('account.created', AccountCreatedEvent, account, params).call
  end

  def log_failed_attempt(errors)
    filters = Rails.application.config.filter_parameters
    f = ActiveSupport::ParameterFilter.new filters
    filtered_params = f.filter params

    Rails.logger.info("Sign-up logs: unsuccessful registration: #{errors}.  params: #{filtered_params}")
  end

  def log_successful_attempt
    Rails.logger.info("Sign-up logs: successful registration: #{params[:email]}")
  end
end
