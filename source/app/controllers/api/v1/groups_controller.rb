# frozen_string_literal: true

class Api::V1::GroupsController < Api::BaseController
  include Authorization

  before_action -> { authorize_if_got_token! :read, :'read:groups' }, only: [:index, :show, :search, :lookup, :validate]
  before_action -> { doorkeeper_authorize! :write, :'write:groups' }, except: [:index, :show, :search, :lookup, :validate]
  before_action :require_user!, except: [:show, :lookup]
  around_action :set_locale, only: [:promote]
  before_action :set_group, except: [:index, :create, :search, :lookup, :validate]
  before_action :require_kept_group, only: [:join]
  before_action :reject_if_exceeding_creation_threshold, only: :create
  before_action :reject_if_exceeding_membership_threshold, only: :create
  after_action :insert_groups_pagination_headers, unless: -> { @groups.nil? }, only: :index
  after_action :insert_search_pagination_headers, unless: -> { @groups.nil? }, only: :search
  after_action :set_total_count_header, only: [:index], if: -> { pending? }

  skip_before_action :require_authenticated_user!, only: :lookup

  DEFAULT_GROUPS_LIMIT = 20
  DEFAULT_GROUPS_SEARCH_LIMIT = 40

  def index
    @groups = Group.my_groups(
      current_account.id, # in_account_id
      display_params[:pending], # in_pending
      display_params[:q], # in_search_query
      limit_param(DEFAULT_GROUPS_LIMIT), # in_limit
      display_params[:offset] # in_offset
    )

    render json: @groups
  end

  def create
    raise Mastodon::ValidationError, I18n.t('groups.errors.too_many_tags') if tag_params.length > 3

    @group = Group.new(create_group_params)

    Tag.find_or_create_by_names(tag_params) do |tag|
      @group.tags << tag
    end

    ApplicationRecord.transaction do
      @group.save!
      @group.memberships.create!(account: current_account, role: :owner)
    end

    render json: REST::V2::GroupSerializer.new(context: { account: current_account }).serialize(@group)
  end

  def update
    authorize @group, :update?

    UpdateGroupService.new(@group, update_group_params, tag_params).call

    render json: REST::V2::GroupSerializer.new(context: { account: current_account, only_pinned_tags: true }).serialize(@group)
  end

  def destroy
    authorize @group, :destroy?
    DestroyGroupService.new(account: current_account, group: @group).call
    render_empty
  end

  def show
    render json: REST::V2::GroupSerializer.new(context: { account: current_account, only_pinned_tags: true }).serialize(@group)
  end

  def join
    join = JoinGroupService.new.call(current_user.account, @group, notify: params.key?(:notify) ? truthy_param?(:notify) : nil)
    options = join.is_a?(GroupMembershipRequest) ? {} : { member_map: { @group.id => { role: join.role, notify: join.notify } }, requested_map: { @group.id => false } }

    render json: REST::GroupRelationshipSerializer.new(context: { relationships: relationships(**options) }).serialize_to_json(@group)
  end

  def leave
    LeaveGroupService.new.call(current_user.account, @group)
    render json: REST::GroupRelationshipSerializer.new(context: { relationships: relationships }).serialize_to_json(@group)
  end

  def promote
    current_membership = @group.memberships.find_by(account_id: current_account.id)
    raise Mastodon::NotPermittedError if current_membership.nil? || rank_from_role(current_membership.role) <= rank_from_role(target_role)

    memberships = @group.memberships.where(account_id: account_ids).to_a
    memberships.each do |membership|
      authorize membership, :change_role?
      raise Mastodon::ValidationError if rank_from_role(membership.role) > rank_from_role(target_role)

      membership.update!(role: target_role)
      GroupRoleChangeNotifyWorker.perform_async(@group.id, membership.account_id, :promotion)
    end

    render json: Panko::ArraySerializer.new(memberships, each_serializer: REST::GroupMembershipSerializer).to_json
  end

  def demote
    current_membership = @group.memberships.find_by(account_id: current_account.id)
    raise Mastodon::NotPermittedError if current_membership.nil? || rank_from_role(current_membership.role) < rank_from_role(target_role)

    memberships = @group.memberships.where(account_id: account_ids).to_a
    memberships.each do |membership|
      authorize membership, :change_role?
      raise Mastodon::ValidationError if rank_from_role(membership.role) < rank_from_role(target_role)

      membership.update!(role: target_role)
      GroupRoleChangeNotifyWorker.perform_async(@group.id, membership.account_id, :demotion)
    end

    render json: Panko::ArraySerializer.new(memberships, each_serializer: REST::GroupMembershipSerializer).to_json
  end

  def search
    @groups = search_groups
    render json: Panko::ArraySerializer.new(@groups, each_serializer: REST::V2::GroupSerializer).to_json
  end

  def lookup
    render json: REST::V2::GroupSerializer.new(context: { account: current_account }).serialize(lookup_group)
  end

  def validate
    invalid_name_message = I18n.t('groups.errors.invalid_name')
    group_name_message = I18n.t('groups.errors.group_taken')
    raise_if_invalid_name(validation_params, "#{invalid_name_message}, Error code #{invalid_name_message}")
    raise_validation_error "#{group_name_message}, Error code #{group_name_message}" if Group.find_by('LOWER(display_name) = ?', validation_params.downcase.squish)

    render_empty
  end

  private

  def rank_from_role(role)
    %i(user admin owner).index(role.to_sym)
  end

  def search_groups
    GroupSearchService.new(
      groups_search_params,
      limit: limit_param(DEFAULT_GROUPS_SEARCH_LIMIT),
      offset: params[:offset]
    ).call
  end

  def set_group
    @group = Group.find(params[:id])
  end

  def require_kept_group
    raise Mastodon::ValidationError, I18n.t('groups.errors.group_deleted') if @group.discarded?
  end

  def reject_if_exceeding_creation_threshold
    raise Mastodon::ValidationError, I18n.t('groups.errors.group_creation_limit') if GroupMembershipValidationService.new(current_account).reached_group_creation_threshold?
  end

  def reject_if_exceeding_membership_threshold
    raise Mastodon::ValidationError, I18n.t('groups.errors.group_membership_limit') if GroupMembershipValidationService.new(current_account).reached_membership_threshold?
  end

  def lookup_group
    [:id, :slug, :name].each do |param|
      next if (value = params[param]).blank?

      return lookup_by_name(value) if param == :name
      return lookup_by_param(param, value)
    end

    raise(ActiveRecord::RecordNotFound)
  end

  def lookup_by_name(name)
    raise_if_invalid_name(name, I18n.t('groups.errors.invalid_name'))

    groups = Group
    groups = groups.everyone unless current_user
    groups.find_by!({ slug: Group.slugify(name) })
  end

  def lookup_by_param(param, value)
    groups = Group
    groups = groups.everyone unless current_user
    groups.find_by!({ param => value })
  end

  def relationships(**options)
    GroupRelationshipsPresenter.new([@group.id], current_user.account_id, **options)
  end

  def resource_params
    params.permit(:role, account_ids: [], tags: [])
  end

  def create_group_params
    mapped_params = params.permit(:display_name, :note, :avatar, :header, :group_visibility, :discoverable, :tags)

    # control status_visibility and locked via publicly exposed group_visibility param
    if (visibility = mapped_params[:group_visibility])
      mapped_params[:statuses_visibility] = visibility
      mapped_params[:locked] = visibility == 'members_only'
    end

    mapped_params[:discoverable] = true if mapped_params[:discoverable].blank?

    # get rid of the group_visibility param after mapping it to statuses_visibility and locked
    # it's only used on the clients for simplicity
    mapped_params.delete(:group_visibility)

    mapped_params[:display_name] = mapped_params[:display_name]&.squish
    mapped_params[:owner_account] = current_account
    mapped_params
  end

  def update_group_params
    params.permit(:note, :avatar, :header, :tags)
  end

  def tag_params
    Array(resource_params[:tags])
  end

  def validation_params
    params.require(:name)
  end

  def account_ids
    Array(resource_params[:account_ids])
  end

  def target_role
    resource_params[:role]
  end

  def insert_groups_pagination_headers
    @groups = JSON.parse(@groups)
    set_pagination_headers(next_groups_path)
  end

  def next_groups_path
    if @groups.size == limit_param(DEFAULT_GROUPS_LIMIT)
      options = {}

      if searching?
        options[:q] = params[:q]
      end

      if pending?
        options[:pending] = params[:pending]
      end

      api_v1_groups_url pagination_params(offset: @groups.size + params[:offset].to_i, **options)
    end
  end

  def insert_search_pagination_headers
    set_pagination_headers(next_path)
  end

  def next_path
    if records_continue?
      search_api_v1_groups_url pagination_params(offset: @groups.size + params[:offset].to_i, q: params[:q])
    end
  end

  def pagination_max_id
    @groups.last.id
  end

  def pagination_since_id
    @groups.first.id
  end

  def records_continue?
    @groups.size >= limit_param(DEFAULT_GROUPS_SEARCH_LIMIT)
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end

  def display_params
    params.slice(:pending, :q, :offset).permit(:pending, :q, :offset)
  end

  def pagination_path(params)
    search_action? ? search_api_v1_groups_url(params) : api_v1_groups_url(params)
  end

  def search_action?
    action_name == 'search'
  end

  def searching?
    params[:q].present?
  end

  def pending?
    params[:pending].present?
  end

  def groups_search_params
    params.require(:q)
  end

  def set_total_count_header
    response.headers['X-Total-Count'] = GroupMembershipRequest.where(account_id: current_account.id)
                                                              .joins(:group)
                                                              .merge(Group.kept)
                                                              .distinct
                                                              .size
  end

  def raise_if_invalid_name(name, message)
    return if ValidGroupNameValidator.valid_name?(name)

    invalid_characters = ValidGroupNameValidator.invalid_characters(name)
    raise_validation_error "#{message}: #{invalid_characters}"
  end

  def raise_validation_error(message)
    raise Mastodon::ValidationError, message
  end
end
