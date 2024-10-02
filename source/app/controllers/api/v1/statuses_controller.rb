# frozen_string_literal: true

class Api::V1::StatusesController < Api::BaseController
  include Authorization
  include Divergable
  include Redisable
  include AdsConcern

  before_action -> { authorize_if_got_token! :read, :'read:statuses' }, except: [:create, :destroy]
  before_action -> { doorkeeper_authorize! :write, :'write:statuses' }, only:   [:create, :destroy]
  before_action :require_user!, except:  [:show, :context, :ancestors, :descendants]
  before_action :set_status, only:       [:show, :context, :ancestors, :descendants]
  before_action :set_thread, only:       [:create]
  before_action :require_authenticated_user!, unless: :allowed_public_access?
  before_action :diverge_users_without_current_ip, only: [:create]
  before_action :set_group, only: [:create]
  before_action :reject_duplicate_group_status, only: [:create]
  after_action :insert_pagination_headers, only: :descendants
  after_action :create_device_verification_status, only: :create

  include Assertable

  override_rate_limit_headers :create, family: :statuses

  # This API was originally unlimited, pagination cannot be introduced without
  # breaking backwards-compatibility. Arbitrarily high number to cover most
  # conversations as quasi-unlimited, it would be too much work to render more
  # than this anyway
  CONTEXT_LIMIT = 4_096
  PAGINATED_LIMIT = 20
  STATUS_HASH_CACHE_EXPIRE_AFTER = 1.hour.seconds
  DUPLICATE_THRESHOLD = 3

  def show
    @status = cache_collection([@status], Status).first

    if (@status.visibility == 'self' && current_user.account_id != @status.account.id) || @status.group&.discarded?
      raise(ActiveRecord::RecordNotFound)
    end

    render json: REST::V2::StatusSerializer.new(context: { current_user: current_user }).serialize(@status)
  end

  def context
    @context = Context.new(ancestors: prepare_ancestors, descendants: prepare_descendants(CONTEXT_LIMIT))
    statuses = [@status] + @context.ancestors + @context.descendants

    render json: @context, serializer: REST::ContextSerializer, relationships: StatusRelationshipsPresenter.new(statuses, current_user&.account_id)
  end

  def descendants
    @descendants = prepare_descendants(PAGINATED_LIMIT)
    include_ad_indexes(@descendants)

    render_context_subitems(@descendants)
  end

  def ancestors
    render_context_subitems(prepare_ancestors)
  end

  def render_context_subitems(statuses)
    render json: statuses, each_serializer: REST::StatusSerializer, relationships: StatusRelationshipsPresenter.new(statuses, current_user&.account_id), exclude_reply_previews: true
  end

  def create
    whitelisted_visibilities = ['public', 'group', nil]
    render json: { error: 'This action is not allowed' }, status: 403 and return unless whitelisted_visibilities.include?(status_params[:visibility])

    @status = PostStatusService.new.call(current_user.account,
                                         text: status_params[:status],
                                         mentions: status_params[:to],
                                         thread: @thread,
                                         media_ids: status_params[:media_ids],
                                         sensitive: status_params[:sensitive],
                                         spoiler_text: status_params[:spoiler_text],
                                         visibility: status_params[:visibility],
                                         group: @group,
                                         group_timeline_visible: status_params[:group_timeline_visible],
                                         group_visibility: @group_visibility || nil,
                                         scheduled_at: status_params[:scheduled_at],
                                         application: doorkeeper_token.application,
                                         poll: status_params[:poll],
                                         quote_id: status_params[:quote_id],
                                         idempotency: request.headers['Idempotency-Key'],
                                         with_rate_limit: true,
                                         ip_address: request.remote_ip,
                                         domain: Addressable::URI.parse(request.url).normalized_host)

    render json: REST::V2::StatusSerializer.new(context: { current_user: current_user }).serialize(@status)
  end

  def destroy
    @status = Status.where(account_id: current_user.account).find(params[:id])
    authorize @status, :destroy?
    @status.reblogs.update_all(deleted_at: Time.current, deleted_by_id: current_user&.account_id)
    @status.update!(deleted_at: Time.current, deleted_by_id: current_user&.account_id)
    @thread = Status.find_by(id: @status.in_reply_to_id) if @status.in_reply_to_id
    RemovalWorker.perform_async(@status.id, redraft: true, called_by_id: current_account.id)
    remove_from_whale_list if @status.account.whale?
    @status.status_pins&.destroy_all

    render json: @status, serializer: REST::StatusSerializer, source_requested: true
  end

  private

  def set_status
    @status = Status.find(params[:id])
    authorize @status, :show?
  rescue Mastodon::NotPermittedError
    raise ActiveRecord::RecordNotFound
  end

  def set_thread
    @thread = status_params[:in_reply_to_id].blank? ? nil : Status.find(status_params[:in_reply_to_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: I18n.t('statuses.errors.in_reply_not_found') }, status: 404
  end

  def set_group
    quoted = status_params[:quote_id].presence && Status.find(status_params[:quote_id])
    group_id = status_params[:group_id].presence || quoted&.group&.id || @thread&.group&.id
    group = Group.find_by(id: group_id) if group_id
    @group = if group&.discarded?
               false
             elsif quoted
               quoted.group&.everyone? ? group_member?(group) && group : group # We don't want to set group if quoted group is a public group and the "quoter" is not a member.
             else
               group
             end

    if @group.present?
      policy = status_params[:quote_id].present? ? :show? : :post?
      authorize(@group, policy)
      @group_visibility = @group.statuses_visibility
    end
  rescue ActiveRecord::RecordNotFound, Mastodon::NotPermittedError
    render json: { error: I18n.t('statuses.errors.not_permitted_to_post') }, status: 404
  end

  def status_params
    params.permit(
      :status,
      :in_reply_to_id,
      :sensitive,
      :spoiler_text,
      :visibility,
      :group_id,
      :group_timeline_visible,
      :scheduled_at,
      :quote_id,
      to: [],
      media_ids: [],
      poll: [
        :multiple,
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
      offset = (params[:offset].to_i || 0) + PAGINATED_LIMIT
      descendants_api_v1_status_url pagination_params(offset: offset)
    end
  end

  def remove_from_whale_list
    FeedManager.instance.remove_from_whale(@status)
  end

  def allowed_public_access?
    current_user || (action_name == 'show' && @status&.account&.user&.unauth_visibility? && !@status&.reply?)
  end

  def validate_client
    action_assertable?
  end

  def asserting?
    request.headers['x-tru-assertion'] && action_assertable?
  end

  def action_assertable?
    %w(create).include?(action_name) ? true : false
  end

  def log_android_activity?
    current_user&.user_sms_reverification_required && action_assertable?
  end

  def create_device_verification_status
    DeviceVerificationStatus.insert(verification_id: @device_verification.id, status_id: @status.id) if @device_verification && @status
  end

  def group_member?(group)
    group&.members&.where(id: current_account&.id)&.exists?
  end

  def reject_duplicate_group_status
    return if @group.blank?
    return if status_params[:status].blank?

    status_hash = hexdigest status_params[:status]
    key = "status:#{current_account.id}:#{status_hash}"
    # cached_value = redis.get(key).to_i
    # configuration = ::Configuration::FeatureSetting.find_by(name: 'rate_limit_duplicate_group_status_enabled')
    # render json: { error: I18n.t('errors.429') }, status: 429 and return if cached_value.to_i >= DUPLICATE_THRESHOLD && ActiveModel::Type::Boolean.new.cast(configuration&.value)

    redis.incrby(key, 1)
    redis.expire(key, STATUS_HASH_CACHE_EXPIRE_AFTER)

    cached_value = redis.get(key).to_i
    if cached_value.to_i >= DUPLICATE_THRESHOLD
      Rails.logger.info "Groups rate limit: User -> #{current_user.id} has exceeded the threshold. Current hits -> #{cached_value.to_i}, remote_ip -> #{request.remote_ip}"
    end
  end
end
