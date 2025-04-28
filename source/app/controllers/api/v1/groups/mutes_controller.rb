# frozen_string_literal: true

class Api::V1::Groups::MutesController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :write, :'read:mutes' }, only: :index
  before_action -> { doorkeeper_authorize! :write, :'write:mutes' }, only: [:create, :destroy]
  before_action :require_user!
  before_action :set_muted_groups, only: [:index]
  before_action :set_group, only: [:create, :destroy]
  after_action :insert_pagination_headers, only: [:index]

  DEFAULT_GROUPS_LIMIT = 20

  def index
    render json: Panko::ArraySerializer.new(@groups, each_serializer: REST::V2::GroupSerializer).to_json
  end

  def create
    GroupMute.find_or_create_by!(account: current_account, group: @group)
    invalidate_carousel_cache
    render json: REST::GroupRelationshipSerializer.new(context: { relationships: relationships }).serialize(@group)
  end

  def destroy
    GroupMute.destroy_by(account: current_account, group: @group)
    render json: REST::GroupRelationshipSerializer.new(context: { relationships: relationships }).serialize(@group)
  end

  private

  def set_muted_groups
    @groups = Group.muted(current_account.id).paginate_by_limit_offset(
      limit_param(DEFAULT_GROUPS_LIMIT),
      params_slice(:offset)
    )
  end

  def set_group
    @group = Group.find(params[:group_id])
  end

  def insert_pagination_headers
    set_pagination_headers(next_path)
  end

  def next_path
    return unless records_continue?
    api_v1_groups_mutes_url pagination_params(offset: @groups.size + params[:offset].to_i)
  end

  def records_continue?
    @groups.size == limit_param(DEFAULT_GROUPS_LIMIT)
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end

  def relationships
    GroupRelationshipsPresenter.new([@group.id], current_user.account_id)
  end

  def invalidate_carousel_cache
    redis.del("groups_carousel_list_#{current_user.account_id}")
  end
end
