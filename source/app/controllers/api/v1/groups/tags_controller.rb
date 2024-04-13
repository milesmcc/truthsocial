# frozen_string_literal: true

class Api::V1::Groups::TagsController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :read, :'read:groups' }, only: :index
  before_action -> { doorkeeper_authorize! :write, :'write:groups' }, only: :update
  before_action :require_user!
  before_action :set_group, only: :update
  before_action :set_tag, only: :update
  before_action :set_group_tag, only: :update
  after_action :insert_pagination_headers, unless: -> { @groups.nil? }, only: :index

  DEFAULT_GROUPS_TAGS_LIMIT = 40

  def index
    @groups = Group.popular_tags(
      limit_param(DEFAULT_GROUPS_TAGS_LIMIT),
      params[:offset].to_i
    )

    render json: @groups || []
  end

  def update
    if @group_tag
      tag_params[:group_tag_type] == 'normal' ? @group_tag.destroy! : @group_tag.update!(tag_params)
    else
      GroupTag.find_or_create_by!(group_id: @group.id, tag_id: @tag.id, group_tag_type: tag_params[:group_tag_type])
    end

    render json: REST::V2::TagSerializer.new.serialize(@tag)
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
    authorize @group, :update?
  end

  def set_tag
    @tag = Tag.find(params[:id])
  end

  def set_group_tag
    @group_tag = GroupTag.find_by(group_id: params[:group_id], tag_id: params[:id])
  end

  def tag_params
    params.permit(:group_tag_type)
  end

  def insert_pagination_headers
    @groups = JSON.parse(@groups)
    set_pagination_headers(next_path)
  end

  def next_path
    if records_continue?
      api_v1_groups_tags_url pagination_params(offset: @groups.size + params[:offset].to_i)
    end
  end

  def records_continue?
    @groups.size == limit_param(DEFAULT_GROUPS_TAGS_LIMIT)
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end
end
