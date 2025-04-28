# frozen_string_literal: true

class Scheduler::TvCreateProgramRecordsScheduler
  include Sidekiq::Worker
  include Redisable

  sidekiq_options retry: 0

  SCHEDULER_FREQUENCY = 5
  DEFAULT_PROGRAM_IMAGE = '/toolbar_logo_icon.png'

  def perform
    channels = TvChannel.joins(:accounts).where(enabled: true)

    return if channels.blank?

    ActiveRecord::Base.connection.truncate(TvProgramTemporary.table_name)

    # fetch the EPG for the next 7 days. This schduler runs every 10 mins.
    now = Time.now
    start_time = now.to_i * 1000
    end_time = (now.to_i + 7.days.to_i) * 1000

    channels.each do |channel|
      programs = PTv::Client::GetEpgService.new.call([channel.channel_id], start_time, end_time)
      next unless programs

      # delete, re-insert programs
      tv_program_records = []
      programs.each do |program|
        image = (program['images'] && program['images'][0]['url']) || ''

        tv_program_records << { channel_id: program['channelId'],
                              name: program['nameSingleLine'],
                              image_url: image,
                              start_time: Time.zone.at(program['startTimestamp'].to_i / 1000).to_datetime,
                              end_time: Time.zone.at(program['endTimestamp'].to_i / 1000).to_datetime,
                              description:  program.dig('show', 'longDescription') || '' }

        # schedule statuses for the next 15 mins
        schedule_status_for_program(program) if ((program['startTimestamp'].to_i / 1000) - now.to_i).round < (15 * 60)
      end

      next if tv_program_records.empty?

      ApplicationRecord.transaction do
        TvProgramTemporary.insert_all(tv_program_records)
      end
    end

    ActiveRecord::Base.connection.exec_query("INSERT INTO tv.programs SELECT * FROM tv.programs_temporary where start_time > $1 ON CONFLICT (channel_id, start_time) DO UPDATE SET name = excluded.name, end_time = excluded.end_time", 'SQL',[now], prepare: true);

    TvProgram
      .where('start_time > ?', now)
      .where.not(TvProgramStatus
                  .where('tv.programs.channel_id = tv.program_statuses.channel_id and tv.programs.start_time = tv.program_statuses.start_time')
                  .arel.exists)
      .where.not(TvProgramTemporary
                  .where('tv.programs.channel_id = tv.programs_temporary.channel_id  and tv.programs.start_time = tv.programs_temporary.start_time')
                  .arel.exists)
      .delete_all
  end

  private

  def schedule_status_for_program(program)
    redis_scheduled_key = "tv:scheduled_program:#{program['channelId']}:#{program['startTimestamp']}"

    return unless program['channelId'] && program['startTimestamp'] && program['endTimestamp'] && program['nameSingleLine']

    return if redis.get(redis_scheduled_key)

    return if TvProgramStatus.where(channel_id: program['channelId']).where(start_time: Time.zone.at(program['startTimestamp'].to_i / 1000).to_datetime).first

    image = (program['images'] && program['images'][0]['url']) || nil

    TvCreateTvProgramStatusWorker.perform_at(program['startTimestamp'].to_i / 1000, program['channelId'], program['nameSingleLine'], program['startTimestamp'], program['endTimestamp'], image)
    redis.set(redis_scheduled_key, true, nx: true, ex: 3.hours.seconds)
  end
end
