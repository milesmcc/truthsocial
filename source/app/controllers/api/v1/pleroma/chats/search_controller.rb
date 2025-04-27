# frozen_string_literal: true
class Api::V1::Pleroma::Chats::SearchController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }, only: [:index, :search_messages, :search_previews]
  before_action :require_user!
  before_action :set_account
  before_action :return_if_empty_search_query, only: [:index, :search_messages]
  after_action :insert_pagination_headers, unless: -> { @search_results.nil? }, only: [:index, :search_messages]

  DEFAULT_RESULTS_LIMIT = 20
  DEFAULT_PREVIEW_LIMIT = 4

  def index
    @search_results = ChatSearchResult.load_results(
      @account.id, #in_account_id
      params[:q], #in_search_query
      limit_param(DEFAULT_RESULTS_LIMIT), #in_limit
      params[:offset].to_i || 0 #in_offset
    )

    render json: @search_results || []
  end

  def search_messages
    @search_results = ChatSearchResult.load_message_results(
      @account.id, #in_account_id
      params[:q], #in_search_query
      limit_param(DEFAULT_RESULTS_LIMIT), #in_limit
      params[:offset].to_i || 0 #in_offset
    )

    render json: @search_results || []
  end

  def search_previews
    @search_results = ChatSearchResult.load_message_previews(
      @account.id, #in_account_id
      limit_param(DEFAULT_PREVIEW_LIMIT)
    )

    render json: @search_results || []
  end

  private

  def return_if_empty_search_query
    render json: [] if params[:q].blank?
  end

  def set_account
    @account = current_user.account
  end

  def insert_pagination_headers
    @search_results = JSON.parse(@search_results)
    set_pagination_headers(next_path)
  end

  def next_path
    if records_continue?
      pagination_path pagination_params(offset: @search_results.size + params[:offset].to_i)
    end
  end

  def records_continue?
    @search_results.size == limit_param(DEFAULT_RESULTS_LIMIT)
  end

  def pagination_path(params)
    if action_name == "search_messages"
      api_v1_pleroma_chats_search_messages_url params
    else
      api_v1_pleroma_chats_search_url params
    end
  end

  def pagination_params(core_params)
    params.slice(:limit, :offset, :q).permit(:limit, :offset, :q).merge(core_params)
  end
end
