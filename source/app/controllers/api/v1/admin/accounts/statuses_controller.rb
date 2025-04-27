# frozen_string_literal: true

class Api::V1::Admin::Accounts::StatusesController < Api::BaseController
  include Authorization
  include AccountableConcern

  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!
  before_action :set_account
  before_action :set_statuses
  after_action :set_pagination_headers

  DEFAULT_LIMIT = 3

  def index
    render json: @statuses, each_serializer: REST::Admin::StatusSerializer, source_requested: true
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end

  def set_statuses
    @statuses = @account.statuses.page(params[:page]).per(DEFAULT_LIMIT)
  end

  def set_pagination_headers
    response.headers['x-page-size'] = DEFAULT_LIMIT
    response.headers['x-page'] = params[:page] || 1
    response.headers['x-total'] = @account.statuses.size
    response.headers['x-total-pages'] = @statuses.total_pages
  end
end
