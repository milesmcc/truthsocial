# frozen_string_literal: true
class Api::V1::Tv::CarouselController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }, only: :index
  before_action -> { doorkeeper_authorize! :write }, only: :seen
  before_action :require_user!

  def index
    render json: Panko::ArraySerializer.new(
      carousel_data,
      each_serializer: REST::V2::TvCarouselSerializer,
      context: {
        guide_data: guide_data
      }
    ).to_json
  end

  def seen
    TvCarousel.new(current_account).mark_seen(target_channel)
    render json: { status: :success }
  end

  private

  def carousel_data
    TvCarousel.new(current_account).get
  end

  def target_channel
    TvChannel.find(params[:channel_id])
  end

  def guide_data
    TvProgram.select('channel_id, MIN(start_time) start_time,  MAX(start_time) max_start_time').group('channel_id').all.map { |f| [f.channel_id, f] }.to_h
  end
end
