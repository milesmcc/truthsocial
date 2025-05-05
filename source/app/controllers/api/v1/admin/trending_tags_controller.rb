# frozen_string_literal: true
class Api::V1::Admin::TrendingTagsController < Api::BaseController
  TRENDING_TAGS_LIMIT = 20
  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!
  before_action :set_tags, only: :index
  after_action :set_pagination_headers, only: :index

  def index
    render json: @tags, each_serializer: REST::Admin::TagSerializer
  end

  def update
    mark_trending_tag_as_false(params[:id])
  end

  private

  def set_tags
    hours_ago = params[:hours_ago] ? params[:hours_ago].to_i.hours.ago : 4.hours.ago
    @tags = Tag.trendable.where(last_status_at: hours_ago..Time.now).page(params[:page]).per(TRENDING_TAGS_LIMIT)
  end

  def mark_trending_tag_as_false(tag_id)
    tag = Tag.find(tag_id)
    tag.trendable = false
    tag.save!
  end

  def set_pagination_headers
    response.headers['x-page-size'] = TRENDING_TAGS_LIMIT
    response.headers['x-page'] = params[:page] || 1
    response.headers['x-total'] = @tags.size
    response.headers['x-total-pages'] = @tags.total_pages
  end
end
