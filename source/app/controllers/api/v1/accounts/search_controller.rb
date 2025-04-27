# frozen_string_literal: true

class Api::V1::Accounts::SearchController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:accounts' }
  before_action :require_user!
  after_action :insert_pagination_headers, unless: -> { @accounts.empty? }, only: :show

  def show
    @accounts = account_search
    render json: @accounts, each_serializer: REST::AccountSerializer, tv_account_lookup: true
  end

  private

  def account_search
    AccountSearchService.new.call(
      params[:q],
      current_account,
      limit: limit_param(DEFAULT_ACCOUNTS_LIMIT),
      resolve: truthy_param?(:resolve),
      following: truthy_param?(:following),
      followers: truthy_param?(:followers),
      offset: params[:offset]
    )
  end

  def insert_pagination_headers
    set_pagination_headers(next_path)
  end

  def next_path
    if records_continue?
      api_v1_accounts_search_url pagination_params(offset: @accounts.size + params[:offset].to_i)
    end
  end

  def records_continue?
    @accounts.size == limit_param(DEFAULT_ACCOUNTS_LIMIT)
  end

  def pagination_params(core_params)
    params.slice(:limit, :followers, :q).permit(:limit, :followers, :q).merge(core_params)
  end
end
