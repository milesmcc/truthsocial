# frozen_string_literal: true

class Api::V1::Tags::GroupsController < Api::BaseController
  before_action -> { authorize_if_got_token! :read, :'read:groups' }
  before_action :require_user!
  before_action :set_tag
  after_action :insert_pagination_headers, unless: -> { @groups.nil? }

  DEFAULT_TAG_GROUPS_LIMIT = 20

  def index
    @groups = Group.with_tag(
      @tag.name, # in_tag_name,
      limit_param(DEFAULT_TAG_GROUPS_LIMIT), # in_limit
      params[:offset].to_i # in_offset
    )

    render json: @groups || []
  end

  private

  def set_tag
    @tag = Tag.find(params[:tag_id])
  end

  def insert_pagination_headers
    @groups = JSON.parse(@groups)
    set_pagination_headers(next_path)
  end

  def next_path
    if records_continue?
      api_v1_tag_groups_url pagination_params(offset: @groups.size + params[:offset].to_i)
    end
  end

  def records_continue?
    @groups.size == limit_param(DEFAULT_TAG_GROUPS_LIMIT)
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end
end
