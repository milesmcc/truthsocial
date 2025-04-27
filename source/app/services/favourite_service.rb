# frozen_string_literal: true

class FavouriteService < BaseService
  include Authorization
  include Payloadable
  include Redisable

  DUPLICATE_FAVOURITE_EXPIRE_AFTER = 7.days.seconds

  # Favourite a status and notify remote user
  # @param [Account] account
  # @param [Status] status
  # @return [Favourite]
  def call(account, status, options = {})
    authorize_with account, status, :favourite?

    favourite = Favourite.find_by(account: account, status: status)

    unless favourite.nil?
      if options[:user_agent]
        redis_key = "duplicate_favourites:#{DateTime.current.to_date}"
        redis_element_key = options[:user_agent]
        redis.zincrby(redis_key, 1, redis_element_key)
        redis.expire(redis_key, DUPLICATE_FAVOURITE_EXPIRE_AFTER)

        Rails.logger.error "duplicate_favourites: #{favourite.id}, difference: #{Time.now.to_i - favourite.created_at.to_i}, user_agent: #{redis_element_key}"
      end

      return favourite
    end

    favourite = Favourite.create!(account: account, status: status)

    read_from_replica do
      create_notification(favourite)
      bump_potential_friendship(account, status)
    end

    export_prometheus_metric

    favourite
  end

  private

  def create_notification(favourite)
    status = favourite.status
    type = status.group ? :group_favourite : :favourite

    if status.account.local?
      NotifyService.new.call(status.account, type, favourite)
    elsif status.account.activitypub?
      ActivityPub::DeliveryWorker.perform_async(build_json(favourite), favourite.account_id, status.account.inbox_url)
    end
  end

  def bump_potential_friendship(account, status)
    ActivityTracker.increment('activity:interactions')
    InteractionsTracker.new(account.id, status.account_id, :favourite, account.following?(status.account_id), status.group).track
  end

  def build_json(favourite)
    Oj.dump(serialize_payload(favourite, ActivityPub::LikeSerializer))
  end

  def export_prometheus_metric
    Prometheus::ApplicationExporter::increment(:favourites)
  end
end
