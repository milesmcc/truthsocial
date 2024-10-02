# frozen_string_literal: true

class Api::V1::Statuses::MutesController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :write, :'write:mutes' }, only: [:create, :destroy]
  before_action -> { doorkeeper_authorize! :write, :'read:mutes' }, only: :index
  before_action :require_user!
  before_action :set_status, only: [:create, :destroy]
  before_action :set_conversation, only: [:create, :destroy]
  after_action :insert_pagination_headers, only: :index

  MUTED_CONVERSATIONS_LIMIT = 20

  def index
    @statuses = load_muted_conversations

    render json: Panko::ArraySerializer.new(
      @statuses,
      each_serializer: REST::V2::StatusSerializer,
      context: {
        current_user: current_user,
        relationships: StatusRelationshipsPresenter.new(@statuses, current_user&.account_id),
      }
    ).to_json
  end

  def create
    current_account.mute_conversation!(@conversation)
    @mutes_map = { @conversation.id => true }

    render json: @status, serializer: REST::StatusSerializer
  end

  def destroy
    current_account.unmute_conversation!(@conversation)
    @mutes_map = { @conversation.id => false }

    render json: @status, serializer: REST::StatusSerializer
  end

  private

  def set_status
    @status = Status.find(params[:status_id])
    authorize @status, :show?
  rescue Mastodon::NotPermittedError
    not_found
  end

  def set_conversation
    @conversation = @status.conversation
    raise Mastodon::ValidationError if @conversation.nil?
  end

  def load_muted_conversations
    scope = paginated_conversations
    @size = scope.size
    @size > limit_param(MUTED_CONVERSATIONS_LIMIT) ? scope.take(limit_param(MUTED_CONVERSATIONS_LIMIT)) : scope
  end

  def paginated_conversations
    Status.muted_conversations_for_account(current_account.id).paginate_by_limit_offset(
      limit_param(MUTED_CONVERSATIONS_LIMIT) + 1,
      params_slice(:offset)
    )
  end

  def insert_pagination_headers
    set_pagination_headers(next_path)
  end

  def next_path
    return unless records_continue?

    api_v1_mutes_url pagination_params(offset: @statuses.size + params[:offset].to_i)
  end

  def records_continue?
    @size > limit_param(MUTED_CONVERSATIONS_LIMIT)
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end
end
