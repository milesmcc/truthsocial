# frozen_string_literal: true
class Api::V1::Pleroma::Chats::EventsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }
  before_action :require_user!
  before_action :set_account
  after_action :insert_pagination_headers, unless: -> { @events.nil? }, only: :index

  DEFAULT_EVENTS_LIMIT = 20

  def index
    @events = ChatEvent.load_events(
      1, # in_api_version
      @account.id, #in_account_id
      nil, #in_chat_id
      nil, # in_upgrade_from_api_version
      params[:max_id], #in_greater_than_event_id
      params[:min_id], #in_less_than_event_id
      true, #in_order_ascending
      limit_param(DEFAULT_EVENTS_LIMIT) #in_page_size
    )

    render json: @events || []
  end

  private

  def set_account
    @account = current_user.account
  end

  def insert_pagination_headers
    @events = JSON.parse(@events)
    set_pagination_headers(next_path, prev_path)
  end

  def next_path
    if records_continue?
      if params[:min_id]
        api_v1_pleroma_chats_events_url pagination_params(min_id: pagination_max_id)
      else
        api_v1_pleroma_chats_events_url pagination_params(max_id: pagination_max_id)
      end
    end
  end

  def prev_path
    unless @events.nil?
      api_v1_pleroma_chats_events_url pagination_params(since_id: pagination_since_id)
    end
  end

  def pagination_max_id
    @events.last['event_id']
  end

  def pagination_since_id
    @events.first['event_id']
  end

  def records_continue?
    @events.size == limit_param(DEFAULT_EVENTS_LIMIT)
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end
end
