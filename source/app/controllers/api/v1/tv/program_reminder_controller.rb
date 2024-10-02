# frozen_string_literal: true
class Api::V1::Tv::ProgramReminderController < Api::BaseController
  before_action -> { doorkeeper_authorize! :write }
  before_action :require_user!
  before_action :set_tv_program
  before_action :set_tv_program_reminder, only: :destroy

  def update
    TvReminder.upsert(
      account_id: current_account.id,
      channel_id: @tv_program.channel_id,
      start_time: @tv_program.start_time
    )
    render json: {}, status: 204
  end

  def destroy
    @tv_program_reminder.destroy
  end

  private

  def set_tv_program
    @tv_program = TvProgram.where(channel_id: params[:id], start_time: Time.zone.at(params[:start_timestamp].to_i / 1000).to_datetime).first
    raise ActiveRecord::RecordNotFound unless @tv_program
  end

  def set_tv_program_reminder
    @tv_program_reminder = TvReminder.where(
      account_id: current_account.id,
      channel_id: @tv_program.channel_id,
      start_time: @tv_program.start_time
    ).first

    raise ActiveRecord::RecordNotFound unless @tv_program_reminder
  end
end
