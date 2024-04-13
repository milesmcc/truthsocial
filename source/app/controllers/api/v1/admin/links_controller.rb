# frozen_string_literal: true

class Api::V1::Admin::LinksController < Api::BaseController
  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!
  before_action :set_link

  def update
    end_url = params[:end_url]
    number_of_redirects = params[:number_of_redirects] || 0

    return unless end_url
    status = BlockedLink.where('? ~ url_pattern', end_url).first&.status || 'normal'

    @link.update(end_url: end_url, status: status, last_visited_at: Time.now, redirects_count: number_of_redirects)
    render json: { success: true }
  end

  private

  def set_link
    @link = Link.find(params[:id])
  end
end
