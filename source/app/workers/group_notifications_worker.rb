class GroupNotificationsWorker
  include Sidekiq::Worker
  include Redisable
  include NotifyConcern

  def perform(recipient_account_id, type, status_id, grouping_key)
    @base_key = base_key(recipient_account_id, type, status_id)
    @grouping_key = grouping_key
    @bucket_key = "#{@base_key}:#{@grouping_key}"
    @current_interval = current_interval(@base_key)
    recipient = Account.find(recipient_account_id)

    update_interval
    @source_account_ids = all_accounts_from_buckets(queued_buckets)
   
    if @source_account_ids.present?
      notification = create_notification!(recipient, type, status_id)
      return unless notification
      push_notification!(notification, recipient)
    end
    cleanup
  end

  def cleanup
    queued_buckets_key = "#{@base_key}:queued_buckets"
    redis.zremrangebyscore(queued_buckets_key, '-inf', @processing_bucket_score) unless @processing_bucket_score.nil?
    redis.del(@bucket_key)
  end

  def update_interval
    current_interval_index = NOTIFICATION_INTERVALS.find_index(@current_interval)
    if (!(next_interval = NOTIFICATION_INTERVALS[current_interval_index + 1]).nil?)
      redis.set("#{@base_key}:current_interval", next_interval)
    end

  end

  def queued_buckets
    queued_buckets_key = "#{@base_key}:queued_buckets"
    @processing_bucket_score ||= redis.zscore(queued_buckets_key, @grouping_key)

    return if @processing_bucket_score.nil?
    buckets = redis.zrangebyscore(queued_buckets_key, '-inf', @processing_bucket_score)
 
    buckets
  end

  def all_accounts_from_buckets(buckets)
    return unless buckets
    subsets = redis.pipelined do |pipeline|
      buckets.each do |bucket|
        pipeline.smembers("#{@base_key}:#{bucket}")
      end
    end

    subsets.flatten.uniq
  end

  def create_notification!(recipient, type, status_id)
    return unless @source_account_ids
    from_account_id = @source_account_ids[0]
    
    if type == "follow"
      activity = Follow.where(account_id: from_account_id, target_account_id: recipient.id).first
    else 
      activity = Status.find_by(id: status_id)
    end
    
    return unless activity

    count = @source_account_ids.length > 1 ? @source_account_ids.length : nil

    @notification = Notification.create(account: recipient, type: "#{type}_group", activity: activity, passed_from_account: from_account_id, count: count)
  end
end
