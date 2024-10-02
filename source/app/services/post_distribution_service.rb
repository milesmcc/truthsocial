# frozen_string_literal: true
class PostDistributionService < BaseService
  include Redisable

  BAILEY_PERCENTAGE = (ENV['BAILEY_PERCENTAGE'] || "0").to_i

  # Enqueue jobs for both author and followers
  def distribute_to_author(status)
    if rand(1..100) <= BAILEY_PERCENTAGE
      QueueManager.enqueue_status_for_author_distribution(status.id)
      Rails.logger.debug("bailey_debug: enqueuing status #{status.id}")
    else
      FanOutOnWriteService.new.call(status)
    end
  end

  def distribute_to_followers(status)
    if rand(1..100) <= BAILEY_PERCENTAGE
      QueueManager.enqueue_status_for_follower_distribution(status.id)
      Rails.logger.debug("bailey_debug: enqueuing status #{status.id}")
    else
      FanOutOnWriteService.new.call(status)
    end
  end

  def distribute_to_author_and_followers(status)
    if rand(1..100) <= BAILEY_PERCENTAGE
      QueueManager.enqueue_status_for_author_distribution(status.id)
      QueueManager.enqueue_status_for_follower_distribution(status.id)
      Rails.logger.debug("bailey_debug: enqueuing status #{status.id}")
    else
      FanOutOnWriteService.new.call(status)
    end
  end

end
