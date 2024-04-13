class TvCarousel
  include Redisable

  TOTAL_ITEMS = 100
  FIELDS_TO_SELECT = [:id, :avatar_file_name, :suspended_at, :domain, :username, :file_s3_host].freeze

  def initialize(account)
    @account = account
    @seen_redis_key = "tv_carousel_seen_programs:#{@account.id}"
  end

  def get
    @seen_programs = redis.hgetall(@seen_redis_key)

    seen_list, unseen_list = live_programs.partition { |status| seen?(status.tv_program) }
    seen_list.map { |status| status.seen = true }
    unseen_list.map { |status| status.seen = false }

    unseen_list + seen_list
  end

  def mark_seen(target_channel)
    redis.hset(@seen_redis_key, target_channel.id, Time.now.to_i)
    redis.expire(@seen_redis_key, 1.month.seconds)
    #TODO:
    # InvalidateSecondaryCacheService.new.call('SyncAvatarsSeenAccountsWorker', @account.id, target_channel.id)
  end

  private

  def live_programs
    Status.tv_channels_statuses
  end

  def seen?(program)
    @seen_programs[program.channel_id.to_s].present? && @seen_programs[program.channel_id.to_s].to_i > program.start_time.to_i
  end
end
