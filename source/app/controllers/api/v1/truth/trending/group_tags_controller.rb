# frozen_string_literal: true
class Api::V1::Truth::Trending::GroupTagsController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :read }
  before_action :require_user!
  before_action :set_group
  after_action :insert_pagination_headers, unless: -> { @tags.nil? }

  TRENDING_TAGS_LIMIT = 20

  def show
    @tags = Group.trending_tags(
      current_account.id,
      @group.id,
      limit_param(TRENDING_TAGS_LIMIT),
      params[:offset].to_i
    )

    render json: @tags || []
  end

  private

  def set_group
    @group = Group.find(params[:id])
    authorize @group, :show?
  end

  def insert_pagination_headers
    @tags = JSON.parse(@tags)
    set_pagination_headers(next_path)
  end

  def next_path
    if records_continue?
      truth_trends_groups_url(pagination_params(offset: @tags.size + params[:offset].to_i))
    end
  end

  def records_continue?
    @tags.size == limit_param(TRENDING_TAGS_LIMIT)
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end
end
