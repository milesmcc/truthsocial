# frozen_string_literal: true

class Api::V2::StatusesController < Api::BaseController
  include Authorization
  include AdsConcern

  before_action -> { authorize_if_got_token! :read, :'read:statuses' }
  before_action :set_status
  before_action :require_authenticated_user!
  after_action :insert_pagination_headers

  PAGINATED_LIMIT = 20
  DESCENDANT_SORTING = [:trending, :oldest, :newest, :controversial]

  def descendants
    @descendants = prepare_descendants(PAGINATED_LIMIT)
    include_ad_indexes(@descendants)

    render_context_subitems(@descendants)
  end

  def ancestors
    @ancestors = prepare_ancestors(PAGINATED_LIMIT)
    render_context_subitems(@ancestors)
  end

  def render_context_subitems(statuses)
    render json: Panko::ArraySerializer.new(
      statuses,
      each_serializer: REST::V2::StatusSerializer,
      context: {
        current_user: current_user,
        relationships: StatusRelationshipsPresenter.new(statuses, current_user&.account_id),
        exclude_reply_previews: true,
      }
    ).to_json
  end

  private

  def set_status
    @status = Status.find(params[:id])
    authorize @status, :show?
  rescue Mastodon::NotPermittedError
    raise ActiveRecord::RecordNotFound
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end

  def prepare_ancestors(limit)
    ancestors_results = @status.in_reply_to_id.nil? ? [] : @status.ancestors_v2(limit, current_account, params[:offset].to_i)
    cache_collection(ancestors_results, Status, true)
  end

  def prepare_descendants(limit)
    descendants_results = @status.descendants_v2(limit, current_account, params[:offset].to_i, sort)
    cache_collection(descendants_results, Status, false)
  end

  def insert_pagination_headers
    set_pagination_headers(next_path) if action_name == 'descendants'
    set_pagination_headers(nil, prev_path) if action_name == 'ancestors'
  end

  def next_path
    if records_continue?
      descendants_api_v2_status_url pagination_params(sort: sort, offset: offset)
    end
  end

  def prev_path
    if records_continue?
      ancestors_api_v2_status_url pagination_params(offset: offset)
    end
  end

  def offset
    (params[:offset].to_i || 0) + PAGINATED_LIMIT
  end

  def records_continue?
    return unless @status.statuses_count_before_filter
    @status.statuses_count_before_filter >= PAGINATED_LIMIT
  end

  def sort
    DESCENDANT_SORTING.include?(params[:sort]&.to_sym) ? params[:sort]&.to_sym : :trending
  end
end
