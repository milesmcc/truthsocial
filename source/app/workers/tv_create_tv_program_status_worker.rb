# frozen_string_literal: true

class TvCreateTvProgramStatusWorker
  include Sidekiq::Worker
  include RoutingHelper

  sidekiq_options retry: 5

  def perform(channel_id, name, start_time, end_time, image_url = nil)
    @channel_id = channel_id
    @name = name
    @start_time = start_time
    @end_time = end_time
    @image_url = image_url

    @channel_account = TvChannelAccount.find_by(channel_id: channel_id).account
    return unless @channel_account

    return if TvProgramStatus.where(channel_id: @channel_id).where(start_time: Time.zone.at(@start_time.to_i / 1000).to_datetime).first

    @tv_program = TvProgram.where(channel_id: @channel_id).where(start_time: Time.zone.at(@start_time.to_i / 1000).to_datetime).first

    return unless @tv_program

    @status = nil

    ApplicationRecord.transaction do
      attachment = create_attachment
      @status = create_status(attachment)
      create_program(@status)
    end

    send_notifications
    Redis.current.lpush('elixir:distribution', Oj.dump(job_type: 'status_created', status_id: @status.id, rendered: nil))
  end

  private

  def create_attachment
    image = if @image_url
              "#{ENV.fetch('TV_BASE_URL', 'https://vstream.truthsocial.com/')}#{@image_url}"
            else
              "#{root_url}tv/#{TvChannel.find(@channel_id).default_program_image_url}"
            end

    file_meta = { 'original' => { 'width' => 1100, 'height' => 618, duration: 0 } }
    params = { file_remote_url: image, file_meta: file_meta, type: 5 }

    @channel_account.media_attachments.create!(params)
  end

  def create_status(media_attachment)
    Status.create!(
      account: @channel_account,
      text: "Watch #{@name}!",
      media_attachments: [media_attachment],
      tv_program_status?: true
    )
  end

  def create_program(status)
    TvProgramStatus.create(
      tv_program: @tv_program,
      tv_channel: TvChannel.find(@channel_id),
      status: status
    )
  end

  def send_notifications
    TvProgramReminderNotificationWorker.perform_async(@channel_id, @start_time)
  end
end
