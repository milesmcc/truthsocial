# frozen_string_literal: true
class Api::V1::Admin::TrendingStatusesController < Api::BaseController
  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!
  before_action :set_statuses, only: :index
  before_action :set_status, only: [:update, :destroy]
  after_action :set_pagination_headers, only: :index

  def index
    render json: @statuses, each_serializer: REST::Admin::StatusSerializer, relationships: StatusRelationshipsPresenter.new(@statuses, current_user&.account_id)
  end

  def update
   mark_trending
  end

  def destroy
    remove_from_trending
  end

  private

  def set_status
    @status = Status.find(params[:id])
  end

  def mark_trending
    trending = Trending.where(status: @status).first_or_initialize
    trending.user = current_user if trending.new_record?
    trending.save!
  end

  def remove_from_trending
    trending = Trending.find_by(status_id: @status.id)
    trending.delete if trending.present?
  end

  def set_statuses
    @statuses = if params[:trending]
                  Trending.includes(:status).all.flat_map(&:status)
                else
                  fetch_recent_statuses
                end
  end

  def fetch_recent_statuses
    Rails.cache.fetch("admin:trending_statuses:#{params[:page]}", expires_in: 10.minutes) do
      Status
        .where(created_at: 1.day.ago.beginning_of_day..Time.now)
        .joins(:status_stat)
        .includes(:preview_cards, :status_stat, account: :account_stat)
        .order("status_stats.favourites_count desc")
        .reorder('')
        .page(params[:page])
        .per(10)
        .to_a
    end
  end

  def set_pagination_headers
    response.headers["x-page-size"] = 10
    response.headers["x-page"] = params[:page] || 1
    response.headers["x-total"] = if @statuses.is_a?(Array)
                                    @statuses.size
                                  else
                                    @statuses.total_count
                                  end

    response.headers["x-total-pages"] = if @statuses.is_a?(Array)
                                          @statuses.size / 10
                                        else
                                          @statuses.total_pages
                                        end
  end
end
