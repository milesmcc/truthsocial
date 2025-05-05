# frozen_string_literal: true

class ReblogService < BaseService
  include Authorization
  include Payloadable
  include Redisable

  DUPLICATE_REBLOG_EXPIRE_AFTER = 7.days.seconds

  # Reblog a status and notify its remote author
  # @param [Account] account Account to reblog from
  # @param [Status] reblogged_status Status to be reblogged
  # @param [Hash] options
  # @option [String]  :visibility
  # @option [Boolean] :with_rate_limit
  # @return [Status]
  def call(account, reblogged_status, options = {})
    reblogged_status = reblogged_status.reblog if reblogged_status.reblog?

    authorize_with account, reblogged_status, :reblog?

    reblog = account.statuses.find_by(reblog: reblogged_status)

    unless reblog.nil?
      if options[:user_agent]
        redis_key = "duplicate_reblogs:#{DateTime.current.to_date}"
        redis_element_key = options[:user_agent]
        redis.zincrby(redis_key, 1, redis_element_key)
        redis.expire(redis_key, DUPLICATE_REBLOG_EXPIRE_AFTER)
      end

      return reblog
    end

    visibility = if reblogged_status.hidden?
                   reblogged_status.visibility
                 else
                   options[:visibility] || account.user&.setting_default_privacy
                 end

    reblog_params = reblogged_status.group_visibility? ? { group_id: reblogged_status.group.id } : {}
    reblog = account.statuses.create!(reblog: reblogged_status, text: '', visibility: visibility, rate_limit: options[:with_rate_limit], **reblog_params)

    PostDistributionService.new.distribute_to_author_and_followers(reblog)
    ActivityPub::DistributionWorker.perform_async(reblog.id)

    create_notification(reblog)
    bump_potential_friendship(account, reblog)
    record_use(account, reblog)
    export_prometheus_metric

    reblog
  end

  private

  def create_notification(reblog)
    reblogged_status = reblog.reblog
    type = reblogged_status.group ? :group_reblog : :reblog

    if reblogged_status.account.local?
      LocalNotificationWorker.perform_async(reblogged_status.account_id, reblog.id, reblog.class.name, type)
    elsif reblogged_status.account.activitypub? && !reblogged_status.account.following?(reblog.account)
      ActivityPub::DeliveryWorker.perform_async(build_json(reblog), reblog.account_id, reblogged_status.account.inbox_url)
    end
  end

  def bump_potential_friendship(account, reblog)
    ActivityTracker.increment('activity:interactions')
    InteractionsTracker.new(account.id, reblog.reblog.account_id, :reblog, account.following?(reblog.reblog.account_id), reblog.group).track
  end

  def record_use(account, reblog)
    return unless reblog.public_visibility?

    original_status = reblog.reblog

    original_status.tags.each do |tag|
      tag.use!(account)
    end
  end

  def build_json(reblog)
    Oj.dump(serialize_payload(ActivityPub::ActivityPresenter.from_status(reblog), ActivityPub::ActivitySerializer, signer: reblog.account))
  end

  def export_prometheus_metric
    Prometheus::ApplicationExporter::increment(:retruths)
  end
end
