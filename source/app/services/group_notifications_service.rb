# frozen_string_literal: true
class GroupNotificationsService < BaseService
  include Redisable
  include NotifyConcern

  def call(recipient_account_id, source_account_id, type, status)
    @current_time = Time.now
    @base_key = base_key(recipient_account_id, type, status&.id)
    @current_interval = current_interval(@base_key)
    @bucket_key = "#{@base_key}:#{grouping_key}"

    add_source_account_to_bucket(source_account_id)
    schedule_bucket_for_processing(recipient_account_id, type, status)
  end

  def add_source_account_to_bucket(source_account_id)
    redis.sadd(@bucket_key, source_account_id)
  end

  def schedule_bucket_for_processing(recipient_account_id, type, status)
    if redis.getset("#{@bucket_key}:queued", 1).nil?
      redis.expire(@bucket_key, 60.minutes.seconds)
      params = [recipient_account_id, type, status&.id, grouping_key]
      if @current_interval < 60
        GroupNotificationsWorker.perform_in(@current_interval, *params)
      else
        schedule_at = @current_time.next_quarter(@current_interval)
        GroupNotificationsWorker.perform_at(schedule_at, *params)
      end
      add_to_queued_list
    end
  end

  def add_to_queued_list
    redis.zadd("#{@base_key}:queued_buckets", @current_time.to_i, grouping_key)
    redis.expire("#{@base_key}:queued_buckets", 1.day.seconds)
  end

  def grouping_key
    base_time = @current_time.strftime('%Y-%m-%d:%H')
    if @current_interval < 60
      @current_interval
    else
      "#{base_time}:#{current_quarter_index}"
    end
  end

  def current_quarter_index
    minutes = @current_time.strftime('%M').to_i
    seconds = @current_time.strftime('%S').to_i
    ((minutes * 60 + seconds).to_f / @current_interval).floor
  end
end

class Time
  def next_quarter(seconds = 60)
    Time.at((to_f / seconds).ceil * seconds)
  end
end