# frozen_string_literal: true

class Api::V1::Admin::Truth::Suggestions::GroupsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :'admin:read' }, only: [:index, :show]
  before_action -> { doorkeeper_authorize! :'admin:write' }, only: [:create, :destroy]
  before_action :require_staff!
  before_action :set_group_suggestion, only: [:show, :destroy]
  before_action :set_group, only: [:create]
  after_action :set_pagination_headers, only: :index

  DEFAULT_GROUP_SUGGESTIONS_LIMIT = 20

  def index
    @group_suggestions = list_group_suggestions
    render json: Panko::ArraySerializer.new(@group_suggestions, each_serializer: REST::V2::GroupSerializer, context: { owner_avatar: true }).to_json
  end

  def show
    render json: REST::V2::GroupSerializer.new(context: { owner_avatar: true }).serialize_to_json(@group)
  end

  def create
    group_suggestion = GroupSuggestion.find_or_create_by!(group: @group)
    render json: REST::GroupSuggestionSerializer.new.serialize_to_json(group_suggestion)
  end

  def destroy
    GroupSuggestion.destroy_by(group: @group)
  end

  private

  def set_group_suggestion
    if params[:slug]
      @group = Group.suggestions.find_by!(slug: params[:slug])
    elsif params[:id]
      @group = Group.suggestions.find_by!(id: params[:id])
    end
  end

  def set_group
    @group = Group.find_by!(slug: group_suggestion_params)
  end

  def group_suggestion_params
    params.require(:group_slug)
  end

  def list_group_suggestions
    Group.includes(:tags)
         .suggestions
         .page(params[:page])
         .per(DEFAULT_GROUP_SUGGESTIONS_LIMIT)
  end

  def set_pagination_headers
    response.headers['x-page-size'] = DEFAULT_GROUP_SUGGESTIONS_LIMIT
    response.headers['x-page'] = params[:page] || 1
    response.headers['x-total'] = @group_suggestions.size
    response.headers['x-total-pages'] = @group_suggestions.total_pages
  end
end
