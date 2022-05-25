# frozen_string_literal: true

class Api::V1::StatusesController < Api::BaseController
  include Authorization

  before_action -> { authorize_if_got_token! :read, :'read:statuses' }, except: [:create, :destroy]
  before_action -> { doorkeeper_authorize! :write, :'write:statuses' }, only:   [:create, :destroy]
  before_action :require_user!, except:  [:show, :context, :ancestors, :descendants]
  before_action :set_status, only:       [:show, :context, :ancestors, :descendants]
  before_action :set_status, only:       [:show, :context, :ancestors, :descendants]
  before_action :set_thread, only:       [:create]
  after_action :insert_pagination_headers, only: :descendants

  override_rate_limit_headers :create, family: :statuses

  # This API was originally unlimited, pagination cannot be introduced without
  # breaking backwards-compatibility. Arbitrarily high number to cover most
  # conversations as quasi-unlimited, it would be too much work to render more
  # than this anyway
  CONTEXT_LIMIT = 4_096
  PAGINATED_LIMIT = 20

  def show
    @status = cache_collection([@status], Status).first
    render json: @status, serializer: REST::StatusSerializer
  end

  def context
    @context = Context.new(ancestors: prepare_ancestors, descendants: prepare_descendants(CONTEXT_LIMIT))
    statuses = [@status] + @context.ancestors + @context.descendants

    render json: @context, serializer: REST::ContextSerializer, relationships: StatusRelationshipsPresenter.new(statuses, current_user&.account_id)
  end

  def descendants
    @descendants = prepare_descendants(PAGINATED_LIMIT)
    render_context_subitems(@descendants)
  end

  def ancestors
    render_context_subitems(prepare_ancestors)
  end

  def render_context_subitems(statuses)
    render json: statuses, each_serializer: REST::StatusSerializer, relationships: StatusRelationshipsPresenter.new(statuses, current_user&.account_id)
  end

  def create
    @status = PostStatusService.new.call(current_user.account,
                                         text: status_params[:status],
                                         mentions: status_params[:to],
                                         thread: @thread,
                                         media_ids: status_params[:media_ids],
                                         sensitive: status_params[:sensitive],
                                         spoiler_text: status_params[:spoiler_text],
                                         visibility: status_params[:visibility],
                                         scheduled_at: status_params[:scheduled_at],
                                         application: doorkeeper_token.application,
                                         poll: status_params[:poll],
                                         idempotency: request.headers['Idempotency-Key'],
                                         with_rate_limit: true)

    render json: @status, serializer: @status.is_a?(ScheduledStatus) ? REST::ScheduledStatusSerializer : REST::StatusSerializer
  end

  def destroy
    @status = Status.where(account_id: current_user.account).find(params[:id])
    authorize @status, :destroy?

    @status.reblogs.update_all(deleted_at: Time.current, deleted_by_id: current_user&.account_id)
    @status.update!(deleted_at: Time.current, deleted_by_id: current_user&.account_id)
    RemovalWorker.perform_async(@status.id, redraft: true)
    remove_from_whale_list if @status.account.whale?
    @status.account.statuses_count = @status.account.statuses_count - 1

    render json: @status, serializer: REST::StatusSerializer, source_requested: true
  end

  private

  def set_status
    @status = Status.find(params[:id])
    authorize @status, :show?
  rescue Mastodon::NotPermittedError
    not_found
  end

  def set_thread
    @thread = status_params[:in_reply_to_id].blank? ? nil : Status.find(status_params[:in_reply_to_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: I18n.t('statuses.errors.in_reply_not_found') }, status: 404
  end

  def status_params
    params.permit(
      :status,
      :in_reply_to_id,
      :sensitive,
      :spoiler_text,
      :visibility,
      :scheduled_at,
      to: [],
      media_ids: [],
      poll: [
        :multiple,
        :hide_totals,
        :expires_in,
        options: [],
      ]
    )
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end

  def prepare_ancestors
    ancestors_results = @status.in_reply_to_id.nil? ? [] : @status.ancestors(CONTEXT_LIMIT, current_account)
    cache_collection(ancestors_results, Status)
  end

  def prepare_descendants(limit)
    descendants_results = @status.descendants(limit, current_account, params[:offset].to_i)
    cache_collection(descendants_results, Status)
  end

  def insert_pagination_headers
    set_pagination_headers(next_path)
  end

  def next_path
    unless @descendants.empty?
      offset =  (params[:offset].to_i || 0) + PAGINATED_LIMIT
      descendants_api_v1_status_url pagination_params(offset: offset)
    end
  end

  def remove_from_whale_list
    FeedManager.instance.remove_from_whale(@status)
  end

end
