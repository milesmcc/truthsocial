# frozen_string_literal: true

class Scheduler::TvRefetchChannelsListScheduler
  include Sidekiq::Worker
  sidekiq_options retry: 0

  SCHEDULER_FREQUENCY = 5

  def perform
    channels_list = PTv::Client::GetChannelsListService.new.call
    return unless channels_list

    channels_list.each do |channel|
      next unless channel['id'] && channel['name'] && channel['images']

      TvChannel.upsert(
        channel_id: channel['id'],
        name: channel['name'],
        image_url: channel['images'][2]['url'] || channel['images'][1]['url'] || '',
        pltv_timespan: channel['pltvTimespan'] || 0
      )
    end
  end
end
