class Api::V1::Admin::Groups::StatusesController < Api::BaseController
  include Authorization

  DEFAULT_STATUSES_LIMIT = 3

  before_action -> { doorkeeper_authorize! :'admin:read', :'admin:read:groups' }, only: [:index]
  before_action :require_staff!
  before_action :set_group
  before_action :set_statuses, only: [:index]
  after_action :set_pagination_headers, only: [:index]

  def index
    render json: @statuses, each_serializer: REST::Admin::StatusSerializer, source_requested: true
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_statuses
    @statuses = @group.statuses.includes(:account).page(params[:page]).per(DEFAULT_STATUSES_LIMIT)
  end

  def set_pagination_headers
    response.headers['x-page-size'] = DEFAULT_STATUSES_LIMIT
    response.headers['x-total'] = @statuses.size
    response.headers['x-total-pages'] = @statuses.total_pages
    response.headers['x-page'] = params[:page] || 1
  end
end
