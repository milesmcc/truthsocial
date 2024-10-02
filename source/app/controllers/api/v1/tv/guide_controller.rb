# frozen_string_literal: true

class Api::V1::Tv::GuideController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:statuses' }
  before_action :require_user!
  before_action :set_data

  def show
    render json: Panko::ArraySerializer.new(
      @epg,
      each_serializer: REST::V2::TvChannelGuideSerializer,
      context: {
        reminders: @reminders
      }
    ).to_json
  end

  def set_data
    @tv_channel = TvChannel.find(params[:id])

    start_timestamp = params[:start_timestamp]&.to_i&.positive? ? Time.zone.at(params[:start_timestamp].to_i / 1000).to_datetime : DateTime.now.in_time_zone(Time.zone).beginning_of_day
    end_timestamp = params[:end_timestamp]&.to_i&.positive? ? Time.zone.at(params[:end_timestamp].to_i / 1000).to_datetime : DateTime.now.in_time_zone(Time.zone).end_of_day

    @epg = TvProgram
          .includes(:tv_program_status, :tv_channel)
          .references(:tv_program_status, :tv_channel)
          .where(channel_id: @tv_channel.id)
          .where('tv.programs.start_time >= ?', start_timestamp)
          .where('tv.programs.start_time <= ?', end_timestamp)

    @reminders = @epg
          .merge(TvProgram
              .includes(:tv_reminder)
              .where(tv_reminder: {account_id: current_account.id})
              )
          .all
          .pluck(:channel_id, :start_time, :account_id)
          .map { |channel_id, start_time, account_id| {channel_id: channel_id, start_time: start_time.to_i * 1000, account_id: account_id}}
    @epg = @epg.order("4 asc")
  end
end
