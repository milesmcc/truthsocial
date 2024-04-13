# frozen_string_literal: true
class Api::V1::Admin::TrendingGroupsController < Api::BaseController
  TRENDING_GROUPS_LIMIT = 10

  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!
  before_action :set_groups, only: :index
  before_action :set_excluded_groups, only: :excluded
  before_action :set_group, only: [:include, :exclude]
  after_action :set_index_pagination_headers, only: :index
  after_action :set_excluded_pagination_headers, only: :excluded

  def index
    render json: @groups || [], each_serializer: REST::V2::GroupSerializer
  end

  def excluded
    render json: @groups || [], each_serializer: REST::V2::GroupSerializer
  end

  def include
    Group.include_in_trending(@group.id)
    render json: REST::V2::GroupSerializer.new.serialize(@group)
  end

  def exclude
    Group.exclude_from_trending(@group.id)
    render json: REST::V2::GroupSerializer.new.serialize(@group)
  end

  private

  def set_group
    @group = Group.find(params[:id])
  end

  def set_groups
    @groups = Group.trending(
      current_account.id,
      limit_param(TRENDING_GROUPS_LIMIT),
      params[:offset].to_i
    )
  end

  def set_excluded_groups
    query = Group.excluded_from_trending(
      limit_param(TRENDING_GROUPS_LIMIT),
      page
    )

    @groups = query['json']
    @total_pages = (query['total_results'].to_f / limit_param(TRENDING_GROUPS_LIMIT)).ceil()
  end

  def page
    params[:page].present? ? params[:page].to_i : 1
  end

  def current_page
    return 1 if params[:offset].nil?
    (limit_param(TRENDING_GROUPS_LIMIT) + params[:offset].to_i) / limit_param(TRENDING_GROUPS_LIMIT)
  end

  def set_index_pagination_headers
    response.headers['x-page-size'] = limit_param(TRENDING_GROUPS_LIMIT)
    response.headers['x-page'] = current_page
    response.headers['x-total'] = JSON.parse(@groups).size
  end

  def set_excluded_pagination_headers
    response.headers['x-page-size'] = limit_param(TRENDING_GROUPS_LIMIT)
    response.headers['x-page'] = page
    response.headers['x-total'] = JSON.parse(@groups).size
    response.headers['x-total-pages'] = @total_pages
  end
end
