# frozen_string_literal: true

class DistributionWorker
  include Sidekiq::Worker
  sidekiq_options queue: "distribution"

  BAILEY_PERCENTAGE = (ENV['BAILEY_PERCENTAGE'] || "0").to_i

  def perform(status_id)
    RedisLock.acquire(redis: Redis.current, key: "distribute:#{status_id}", autorelease: 5.minutes.seconds) do |lock|
      if lock.acquired?
        @status = Status.find(status_id)
        if rand(1..100) <= BAILEY_PERCENTAGE && !@status.account.whale?
          send_to_bailey(status_id)
        else
          FanOutOnWriteService.new.call(Status.find(status_id))
        end
      else
        raise Mastodon::RaceConditionError
      end
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.info("bailey_debug: record not found for status #{status_id}")
    true
  end

  def send_to_bailey(status_id)
    QueueManager.enqueue_status_for_author_distribution(status_id)
    QueueManager.enqueue_status_for_follower_distribution(status_id)
    Rails.logger.debug("bailey_debug: enqueuing status #{status_id}")
  end
end
