# frozen_string_literal: true

class Api::V1::Timelines::GroupTagController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :read, :'read:groups' }
  before_action :require_user!
  before_action :load_tag
  after_action :insert_pagination_headers, unless: -> { @statuses.empty? }

  def show
    @statuses  = load_statuses
    account_ids = @statuses.filter(&:quote?).map { |status| status.quote.account_id }.uniq
    render json: @statuses, each_serializer: REST::StatusSerializer, relationships: StatusRelationshipsPresenter.new(@statuses, current_user&.account_id), account_relationships: AccountRelationshipsPresenter.new(account_ids, current_user&.account_id)
  end

  private

  def load_tag
    @tag = Tag.find_normalized(params[:id])
  end

  def load_statuses
    cached_tagged_statuses
  end

  def cached_tagged_statuses
    @tag.nil? ? [] : cache_collection(group_tag_timeline_statuses, Status)
  end

  def group_tag_timeline_statuses
    group_tag_feed.get(
      limit_param(DEFAULT_STATUSES_LIMIT),
      params[:max_id],
      params[:since_id],
      params[:min_id]
    )
  end

  def group_tag_feed
    TagFeed.new(
      @tag,
      current_account,
      group_id: params[:group_id]
    )
  end

  def insert_pagination_headers
    set_pagination_headers(next_path, prev_path)
  end

  def pagination_params(core_params)
    params.permit(:max_id, :min_id, :limit).merge(core_params)
  end

  def next_path
    api_v1_timelines_group_tag_url params[:group_id], params[:id], pagination_params(max_id: pagination_max_id)
  end

  def prev_path
    api_v1_timelines_group_tag_url params[:group_id], params[:id], pagination_params(min_id: pagination_since_id)
  end

  def pagination_max_id
    @statuses.last.id
  end

  def pagination_since_id
    @statuses.first.id
  end
end
