# frozen_string_literal: true
class Api::V1::Truth::Trending::TruthsController < Api::BaseController
  before_action :set_trendings
  before_action :set_truths

  TRENDING_TAGS_LIMIT = 10

  def index
    render json: @truths, each_serializer: REST::StatusSerializer, relationships: StatusRelationshipsPresenter.new(@truths, current_user&.account_id)
  end

  private

  def set_trendings
    @trendings = Trending.limit(TRENDING_TAGS_LIMIT).all
  end

  def set_truths
    @truths = load_statuses
  end

  def load_statuses
    cached_tagged_statuses
  end

  def cached_tagged_statuses
    cache_collection(all_trending_timeline_statuses, Status)
  end

  def all_trending_timeline_statuses
    @trendings.flat_map(&:status)
  end
end
