# frozen_string_literal: true

class Api::V1::Timelines::GroupController < Api::BaseController
  include Authorization
  include LinksParserConcern

  before_action :set_group
  before_action -> { authorize_if_got_token! :read, :'read:groups' }
  before_action :require_authenticated_user!, unless: :allowed_access?
  before_action :set_statuses
  after_action :insert_pagination_headers, unless: -> { @statuses.empty? }

  def show
    authorize @group, :show_group_statuses?

    if @statuses.count >= 10 && @group.everyone?
      response.headers['x-truth-ad-indexes'] = '1,8,15'
    end

    render json: Panko::ArraySerializer.new(
      @statuses,
      each_serializer: REST::V2::StatusSerializer,
      context: {
        current_user: current_user,
        relationships: StatusRelationshipsPresenter.new(@statuses, current_user&.account_id, @group.id),
      }
    ).to_json
  end

  private

  def set_group
    @group = Group.kept.find(params[:id])
  end

  def set_statuses
    @statuses = cached_group_statuses
    @total_statuses_before_filter = @statuses.size
    @statuses.reject! { |status| filter_status?(status) }
  end

  def cached_group_statuses
    cache_collection group_statuses, Status
  end

  def group_statuses
    group_feed.get(
      limit_param(DEFAULT_STATUSES_LIMIT),
      params[:max_id],
      params[:since_id],
      params[:min_id]
    )
  end

  def group_feed
    GroupFeed.new(
      @group,
      current_account,
      only_media: truthy_param?(:only_media),
      only_pinned: truthy_param?(:pinned),
      unauthenticated: !current_user,
    )
  end

  def insert_pagination_headers
    set_pagination_headers(next_path, prev_path)
  end

  def pagination_params(core_params)
    params.slice(:limit, :only_media).permit(:limit, :only_media).merge(core_params)
  end

  def next_path
    api_v1_timelines_group_url params[:id], pagination_params(max_id: pagination_max_id) if records_continue?
  end

  def prev_path
    api_v1_timelines_group_url params[:id], pagination_params(min_id: pagination_since_id) unless @statuses.empty?
  end

  def records_continue?
    @total_statuses_before_filter == limit_param(DEFAULT_STATUSES_LIMIT)
  end

  def pagination_max_id
    @statuses.last.id
  end

  def pagination_since_id
    @statuses.first.id
  end

  def filter_status?(status)
    links = extract_urls_including_local(status.text)
    time_difference = (Time.now - status.created_at).round
    links.any? && !status.account.whale? && status.account_id != current_user&.account_id && time_difference < 300
  end

  def allowed_access?
    current_user || @group.everyone?
  end
end
