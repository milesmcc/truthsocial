class Procedure
  def self.process_all_statistics_queues
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_account_follower_statistics_queue" ()')
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_account_following_statistics_queue" ()')
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_account_status_statistics_queue" ()')
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_status_favourite_statistics_queue" ()')
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_status_reblog_statistics_queue" ()')
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_status_reply_statistics_queue" ()')
  end

  def self.delete_expired_chat_messages
    ActiveRecord::Base.connection.execute('call "cron"."delete_expired_chat_messages" ()')
  end

  def self.process_account_follower_statistics_queue
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_account_follower_statistics_queue" ()')
  end

  def self.process_account_following_statistics_queue
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_account_following_statistics_queue" ()')
  end

  def self.process_account_status_statistics_queue
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_account_status_statistics_queue" ()')
  end

  def self.process_chat_events
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_chat_events_queue" ()')
  end

  def self.process_chat_subscribers_queue
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_chat_subscribers_queue" ()')
  end

  def self.process_status_favourite_statistics_queue
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_status_favourite_statistics_queue" ()')
  end

  def self.process_poll_votes_queue
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_poll_votes_queue" ()')
  end

  def self.process_status_reblog_statistics_queue
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_status_reblog_statistics_queue" ()')
  end

  def self.refresh_status_reply_score_queue
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_status_reply_score_queue" ()')
  end

  def self.process_status_reply_statistics_queue
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_status_reply_statistics_queue" ()')
  end

  def self.refresh_group_tag_use_cache
    ActiveRecord::Base.connection.execute('call "elwood_api"."refresh_group_tag_use_cache" ()')
  end

  def self.refresh_tag_use_cache
    ActiveRecord::Base.connection.execute('call "elwood_api"."refresh_tag_use_cache" ()')
  end

  def self.refresh_trending_groups
    ActiveRecord::Base.connection.execute('call "cron"."refresh_trending_groups" ()')
  end

  def self.refresh_trending_statuses
    ActiveRecord::Base.connection.execute('call "cron"."refresh_trending_statuses" ()')
  end

  def self.refresh_trending_tags
    ActiveRecord::Base.connection.execute('call "cron"."refresh_trending_tags" ()')
  end

  def self.process_poll_option_statistics_queue
    ActiveRecord::Base.connection.execute('call "elwood_api"."process_poll_option_statistics_queue" ()')
  end
end
