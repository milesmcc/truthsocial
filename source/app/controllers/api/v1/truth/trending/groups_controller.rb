# frozen_string_literal: true
class Api::V1::Truth::Trending::GroupsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }
  before_action :require_user!
  after_action :insert_pagination_headers, unless: -> { @groups.nil? }

  TRENDING_GROUPS_LIMIT = 20

  def index
    @groups = Group.trending(
      current_account.id, # in_account_id
      limit_param(TRENDING_GROUPS_LIMIT), # in_limit
      params[:offset].to_i # in_offset
    )

    render json: @groups || []
  end

  private

  def insert_pagination_headers
    @groups = JSON.parse(@groups)
    set_pagination_headers(next_path)
  end

  def next_path
    if records_continue?
      api_v1_truth_trends_groups_url pagination_params(offset: @groups.size + params[:offset].to_i)
    end
  end

  def records_continue?
    @groups.size == limit_param(TRENDING_GROUPS_LIMIT)
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end
end
