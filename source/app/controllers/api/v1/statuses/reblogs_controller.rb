# frozen_string_literal: true

class Api::V1::Statuses::ReblogsController < Api::BaseController
  include Authorization
  include Divergable

  before_action -> { doorkeeper_authorize! :write, :'write:statuses' }
  before_action :require_user!
  before_action :diverge_users_without_current_ip, only: [:create]
  before_action :set_reblog, only: [:create]
  after_action :create_device_verification_status, only: :create

  include Assertable

  override_rate_limit_headers :create, family: :statuses

  def create
    @status = ReblogService.new.call(current_account, @reblog, reblog_params)

    @status.reblog.status_reblog || @status.reblog.build_status_reblog
    @status.reblog.status_reblog.reblogs_count = @status.reblog.reblogs_count + 1
    render json: @status, serializer: REST::StatusSerializer
  end

  def destroy
    @status = current_account.statuses.find_by(reblog_of_id: params[:status_id])

    if @status
      authorize @status, :unreblog?
      @status.discard
      ReblogRemovalWorker.perform_async(@status.id, immediate: true)
      @reblog = @status.reblog
      InteractionsTracker.new(current_account.id, @reblog.account_id, :reblog, current_account.following?(@reblog.account_id), @reblog.group).untrack
    else
      @reblog = Status.find(params[:status_id])
      authorize @reblog, :show?
    end

    render json: @reblog, serializer: REST::StatusSerializer, relationships: StatusRelationshipsPresenter.new([@status], current_account.id, reblogs_map: { @reblog.id => false })
  rescue Mastodon::NotPermittedError
    not_found
  end

  private

  def set_reblog
    @reblog = Status.find(params[:status_id])
    authorize @reblog, :show?
  rescue Mastodon::NotPermittedError
    not_found
  end

  def reblog_params
    params.permit(:visibility).merge(user_agent: request.user_agent)
  end

  def validate_client
    action_assertable?
  end

  def asserting?
    request.headers['x-tru-assertion'] && action_assertable?
  end

  def action_assertable?
    %w(create).include?(action_name) ? true : false
  end

  def log_android_activity?
    current_user.user_sms_reverification_required && action_assertable?
  end

  def create_device_verification_status
    DeviceVerificationStatus.insert(verification_id: @device_verification.id, status_id: @status.id) if @device_verification && @status
  end
end
