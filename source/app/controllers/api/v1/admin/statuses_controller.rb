# frozen_string_literal: true

class Api::V1::Admin::StatusesController < Api::BaseController
  include Authorization
  include AccountableConcern

  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action -> { set_status }, except: :index

  def index
    @statuses = Status.with_discarded.where(id: params[:ids])
    authorize @statuses, :index?
    render json: @statuses, each_serializer: REST::Admin::StatusSerializer
  end

  def show
    render json: @status
  end

  def sensitize
    @status.update!(sensitive: true)
    log_action :update, @status
    render json: @status
  end

  def desensitize
    @status.update!(sensitive: false)
    log_action :update, @status
    render json: @status
  end

  def undiscard
    @status.update!(deleted_at: nil, deleted_by_id: nil)
    log_action :update, @status
    render json: @status
  end

  def discard
    @status.update!(deleted_at: Time.current, deleted_by_id: resource_params[:moderator_id])
    RemovalWorker.perform_async(@status.id, redraft: true, notify_user: resource_params[:notify_user])
    @status.account.statuses_count = @status.account.statuses_count - 1
    @status.account.save
    render json: @status, serializer: REST::Admin::StatusSerializer, source_requested: true
  end

  private

  def set_status
    @status = Status.with_discarded.find(params[:id] || params[:status_id])
  end

  def resource_params
    params.permit(:sensitive, :moderator_id, :notify_user)
  end
end
