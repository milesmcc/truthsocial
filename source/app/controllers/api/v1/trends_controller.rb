# frozen_string_literal: true

class Api::V1::TrendsController < Api::BaseController
  before_action :set_tags
  after_action :insert_pagination_headers, only: :index

  DEFAULT_LIMIT = 20

  def index
    render json: @tags || []
  end

  private

  def set_tags
    @tags = TrendingTagsResult.load_results(
      limit, # in_limit
      offset # in_offset
    )
  end

  def limit
    params[:limit].present? ? params[:limit].to_i : DEFAULT_LIMIT
  end

  def offset
    params[:offset].present? ? params[:offset].to_i : 0
  end

  def insert_pagination_headers
    @tags = JSON.parse(@tags || '[]')
    set_pagination_headers(next_path)
  end

  def next_path
    if records_continue?
      api_v1_trends_url pagination_params(offset: @tags.size + params[:offset].to_i)
    end
  end

  def records_continue?
    @tags.size == limit_param(DEFAULT_LIMIT)
  end

  def pagination_params(core_params)
    params.slice(:limit, :page).permit(:limit, :page).merge(core_params)
  end
end
