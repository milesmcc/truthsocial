# frozen_string_literal: true
class Api::V1::Admin::TagsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!
  before_action :set_tags, only: :index
  before_action :set_tag, only: :update
  after_action :set_pagination_headers, only: :index

  DEFAULT_TAGS_LIMIT = 20

  def index
    render json: Panko::ArraySerializer.new(@tags, each_serializer: REST::Admin::TagSearchSerializer).to_json
  end

  def update
    @tag.update(update_params)
    render json: REST::Admin::TagSearchSerializer.new().serialize(@tag)
  end

  private

  def set_tags
    scope = Tag
      .page(params[:page])
      .per(DEFAULT_TAGS_LIMIT)

    scope = scope.search(search_params[:q]) if search_params[:q]
    scope = scope.only_trendable if params[:trendable]
    scope = scope.listable if params[:listable]

    @tags = scope
  end

  def set_tag
    @tag = Tag.find_by!(name: params[:id])
  end

  def search_params
    params.permit(:q)
  end

  def update_params
    params.permit(:trendable, :listable)
  end

  def set_pagination_headers
    response.headers['x-page-size'] = DEFAULT_TAGS_LIMIT
    response.headers['x-page'] = params[:page] || 1
    response.headers['x-total'] = @tags.size
    response.headers['x-total-pages'] = @tags.total_pages
  end
end
