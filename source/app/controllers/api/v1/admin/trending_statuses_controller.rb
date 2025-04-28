# frozen_string_literal: true
class Api::V1::Admin::TrendingStatusesController < Api::BaseController
  TRENDING_STATUS_LIMIT = 10

  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!
  before_action :set_statuses, only: :index
  before_action :set_status, only: [:include, :exclude]
  after_action :set_pagination_headers, only: :index

  def index
    render json: @statuses, each_serializer: REST::Admin::StatusSerializer, relationships: StatusRelationshipsPresenter.new(@statuses, current_user&.account_id)
  end

  def include
    render json: TrendingStatusExcludedStatus.destroy(@status.id)
  end

  def exclude
    render json: TrendingStatusExcludedStatus.create(status_id: @status.id)
  end

  private

  def set_status
    @status = Status.find(params[:id])
  end

  def set_statuses
    @statuses = Status.trending_statuses.page(params[:page]).per(TRENDING_STATUS_LIMIT)
  end

  def set_pagination_headers
    response.headers['x-page-size'] = TRENDING_STATUS_LIMIT
    response.headers['x-page'] = params[:page] || 1
    response.headers['x-total'] = @statuses.size
    response.headers['x-total-pages'] = @statuses.total_pages
  end
end
