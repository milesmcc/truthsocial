# frozen_string_literal: true

class Api::V1::Tv::AccountsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:statuses' }, only: :show
  before_action :require_user!
  before_action :set_tv_status

  def show
    render(
      json: Panko::Response.create do |r|
        {
          live: @tv_status.present? ? r.serializer(@tv_status, REST::V2::StatusSerializer) : nil,
          channel_id: @tv_channel.id
        }
      end
    )
  end

  def set_tv_status
    @account = Account.find(params[:id])
    @tv_channel = @account.tv_channels.first

    if @tv_channel.nil?
      render json: { error: 'Not a tv account' }, status: 422 and return
    end

    time = params[:timestamp]&.to_i&.positive? ? Time.zone.at(params[:timestamp].to_i / 1000).to_datetime : Time.zone.now

    @tv_status = TvProgram.where(channel_id: @tv_channel.id).where('start_time <= ?', time).where('end_time >= ?', time).order(start_time: :desc).first&.status
  end
end
