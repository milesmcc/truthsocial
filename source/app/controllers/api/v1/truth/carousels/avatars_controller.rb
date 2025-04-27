# frozen_string_literal: true
class Api::V1::Truth::Carousels::AvatarsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }, only: :index
  before_action -> { doorkeeper_authorize! :write }, only: :seen
  before_action :require_user!

  def index
    render json: carousel_data, each_serializer: REST::AvatarsCarouselSerializer
  end

  def seen
    AvatarsCarousel.new(current_account).mark_seen(target_account)
    render json: { status: :success }
  end

  private

  def carousel_data
    AvatarsCarousel.new(current_account).get
  end

  def target_account
    Account.find(params[:account_id])
  end

end
