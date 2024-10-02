# frozen_string_literal: true

class Api::V1::Truth::Suggestions::GroupsController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :read, :'read:groups' }, only: :index
  before_action -> { doorkeeper_authorize! :write, :'write:groups' }, only: :destroy
  before_action :require_user!
  before_action :set_group_suggestion, only: [:destroy]
  after_action :insert_pagination_headers, unless: -> { @group_suggestions.empty? }, only: [:index]

  DEFAULT_GROUP_SUGGESTIONS_LIMIT = 20

  def index
    @group_suggestions = list_group_suggestions
    render json: Panko::ArraySerializer.new(@group_suggestions, each_serializer: REST::V2::GroupSerializer).to_json
  end

  def destroy
    GroupSuggestionDelete.create!(account: current_account, group: @group)
  end

  private

  def list_group_suggestions
    Group.kept
         .includes(:tags)
         .suggestions
         .without_membership(current_account.id)
         .without_requested(current_account.id)
         .without_blocked(current_account.id)
         .without_dismissed(current_account.id)
         .paginate_by_limit_offset(limit_param(DEFAULT_GROUP_SUGGESTIONS_LIMIT), params.slice(:offset))
  end

  def insert_pagination_headers
    set_pagination_headers(next_path)
  end

  def next_path
    if records_continue?
      api_v1_truth_suggestions_groups_url pagination_params(offset: @group_suggestions.size + params[:offset].to_i)
    end
  end

  def records_continue?
    @group_suggestions.size == limit_param(DEFAULT_GROUP_SUGGESTIONS_LIMIT)
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end

  def set_group_suggestion
    @group = Group.suggestions.find_by!(id: params[:id])
  end
end
