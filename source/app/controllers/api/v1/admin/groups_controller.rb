# frozen_string_literal: true

class Api::V1::Admin::GroupsController < Api::BaseController
  include Authorization

  DEFAULT_GROUPS_LIMIT = 20
  DEFAULT_GROUPS_SEARCH_LIMIT = 40

  before_action -> { doorkeeper_authorize! :'admin:read', :'admin:read:groups' }, only: [:index, :show, :search]
  before_action -> { doorkeeper_authorize! :'admin:write', :'admin:write:groups' }, only: [:update, :destroy]
  before_action :require_staff!
  before_action :set_groups, only: :index
  before_action :set_group, only: [:show, :update, :destroy]
  after_action :set_pagination_headers, only: [:index, :search]

  def index
    render json: Panko::ArraySerializer.new(@groups, each_serializer: REST::V2::GroupSerializer, context: { owner_avatar: true, admin: true }).to_json
  end

  def show
    render json: REST::V2::GroupSerializer.new(context: { owner_avatar: true, admin: true }).serialize(@group)
  end

  def update
    UpdateGroupService.new(@group, group_params, tag_params).call
    render json: REST::V2::GroupSerializer.new(context: { account: current_account, owner_avatar: true, admin: true }).serialize(@group)
  end

  def destroy
    @group.discard
    @group.group_suggestion&.destroy
  end

  def search
    @groups = search_groups
    render json: Panko::ArraySerializer.new(@groups, each_serializer: REST::V2::GroupSerializer, context: { owner_avatar: true, admin: true }).to_json
  end

  private

  def set_groups
    @groups = filtered_groups.order(id: :desc).page(params[:page]).per(DEFAULT_GROUPS_LIMIT)
  end

  def set_group
    @group = Group.find(params[:id])
  end

  def search_groups
    Group.with_discarded
         .includes(:group_stat, :tags)
         .search(groups_search_params)
         .page(params[:page])
         .per(DEFAULT_GROUPS_SEARCH_LIMIT)
  end

  def filtered_groups
    GroupFilter.new(filter_params.with_defaults(order: 'recent')).results
  end

  def filter_params
    params.permit(:order, :by_member, by_member_role: [])
  end

  def set_pagination_headers
    response.headers['x-page-size'] = search_action? ? DEFAULT_GROUPS_SEARCH_LIMIT : DEFAULT_GROUPS_LIMIT
    response.headers['x-page'] = params[:page] || 1
    response.headers['x-total'] = @groups.size
    response.headers['x-total-pages'] = @groups.total_pages
  end

  def search_action?
    action_name == 'search'
  end

  def group_params
    params.permit(
      :avatar,
      :discoverable,
      :display_name,
      :header,
      :locked,
      :note,
      :owner_account_id,
      :previous_owner_role,
      :statuses_visibility,
    )
  end

  def tag_params
    Array(params.permit(tags: [])[:tags])
  end

  def groups_search_params
    params.require(:q)
  end
end
