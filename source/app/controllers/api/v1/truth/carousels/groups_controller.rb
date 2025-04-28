# frozen_string_literal: true
class Api::V1::Truth::Carousels::GroupsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }, only: :index
  before_action -> { doorkeeper_authorize! :write }, only: :seen
  before_action :require_user!

  def index
    render json: Panko::ArraySerializer.new(carousel_data, each_serializer: REST::GroupsCarouselSerializer).to_json
  end

  def seen
    GroupsCarousel.new(current_account).mark_seen(target_group)
  end

  private

  def carousel_data
    GroupsCarousel.new(current_account).get
  end

  def target_group
    Group.find(params[:group_id])
  end
end
