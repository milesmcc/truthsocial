# frozen_string_literal: true

class Api::V1::Admin::StatusesController < Api::BaseController
  include Authorization
  include AccountableConcern

  before_action :set_log_level
  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!
  before_action -> { set_status }, except: :index
  after_action :revert_log_level

  def index
    @statuses = Status.with_discarded.where(id: params[:ids])
    authorize @statuses, :index?
    render json: @statuses, each_serializer: REST::Admin::StatusSerializer
  end

  def show
    render json: @status, serializer: REST::Admin::StatusSerializer
  end

  def sensitize
    @status.update!(sensitive: true)
    log_action :update, @status
    invalidate_cache
    render json: @status
  end

  def desensitize
    @status.update!(sensitive: false)
    log_action :update, @status
    invalidate_cache
    render json: @status
  end

  def undiscard
    @status.update!(deleted_at: nil, deleted_by_id: nil)
    log_action :update, @status
    invalidate_cache
    render json: @status
  end

  def discard
    @status.reblogs.update_all(deleted_at: Time.current, deleted_by_id: resource_params[:moderator_id])
    @status.update!(deleted_at: Time.current, deleted_by_id: resource_params[:moderator_id])
    RemovalWorker.perform_async(@status.id, redraft: true, notify_user: resource_params[:notify_user], immediate: false)
    invalidate_cache
    render json: @status, serializer: REST::Admin::StatusSerializer, source_requested: true
  end

  def privatize
    @status.privatize(resource_params[:moderator_id], resource_params[:notify_user])
    invalidate_cache
    render json: @status, serializer: REST::Admin::StatusSerializer, source_requested: true
  end

  def publicize
    @status.publicize
    invalidate_cache
    render json: @status, serializer: REST::Admin::StatusSerializer, source_requested: true
  end

  private

  def set_status
    @status = Status.with_discarded.find(params[:id] || params[:status_id])
    @status.performed_by_admin = true
  end

  def resource_params
    params.permit(:sensitive, :moderator_id, :notify_user)
  end

  def invalidate_cache
    Rails.cache.delete(@status)
    InvalidateSecondaryCacheService.new.call("InvalidateStatusCacheWorker", @status.id)
  end

  def set_log_level
    return unless request.request_method == 'POST'
    Rails.logger.info("Admin::StatusesController logs: #{params.inspect}")
    @current_log_level = Rails.logger.level
    Rails.logger.level = :debug
  end

  def revert_log_level
    return unless request.request_method == 'POST'
    Rails.logger.level = @current_log_level
  end
end
