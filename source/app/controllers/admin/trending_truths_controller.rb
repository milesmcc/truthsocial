# frozen_string_literal: true

module Admin
  class TrendingTruthsController < BaseController
    helper_method :current_params

    before_action :set_statuses, only: [:index, :update, :destroy]
    before_action :set_status, only: [:update, :destroy]

    PER_PAGE = 10

    def index; end

    def update
      mark_trending
    end

    def destroy
      remove_from_trending
    end

    private

    def set_statuses
      @statuses = if params[:trending]
                    Trending.includes(:status).all.flat_map(&:status)
                  else
                    Status.page(params[:page]).per(PER_PAGE)
                  end
    rescue Mastodon::NotPermittedError
      not_found
    end

    def set_status
      @status = Status.find(params[:id])
    rescue Mastodon::NotPermittedError
      not_found
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

    def filter_params
      params.permit(:id, :trending)
    end

    def pagination_params(core_params)
      params.slice(:limit).permit(:limit).merge(core_params)
    end
  end
end
