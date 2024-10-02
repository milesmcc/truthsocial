# frozen_string_literal: true

class RemoveStatusService < BaseService
  include Redisable
  include Payloadable

  BAILEY_PERCENTAGE = (ENV['BAILEY_PERCENTAGE'] || '0').to_i

  # Delete a status
  # @param   [Status] status
  # @param   [Hash] options
  # @option  [Boolean] :redraft
  # @option  [Boolean] :immediate
  # @option  [Boolean] :original_removed
  def call(status, **options)
    @payload  = Oj.dump(event: :delete, payload: status.id.to_s)
    @status   = status
    @account  = status.account
    @immediate = options.key?(:immediate) ? options[:immediate] : false
    @options = options

    @status.discard

    EventProvider::EventProvider.new('status.removed', StatusRemovedEvent, @status, options[:called_by_id]).call if options[:called_by_id] == @status.account_id

    RedisLock.acquire(lock_options) do |lock|
      if lock.acquired?

        remove_user_interactions!
        remove_from_timeline_cache

        if rand(1..100) <= BAILEY_PERCENTAGE
          send_to_bailey
        else
          remove_from_self if @account.local?

          remove_from_followers unless @account.whale?

          remove_from_lists

          remove_from_group

          unless @status.reblog?
            remove_reblogs
          end
        end

        # Since reblogs don't mention anyone, don't get reblogged,
        # favourited and don't contain their own media attachments
        # or hashtags, this can be skipped
        unless @status.reblog?
          # remove_from_mentions
          # remove_reblogs #Moved to 'else block' so maastodon will still handle this if bailey does not
          # remove_from_hashtags #Not used right now.  Can turn on later.
          remove_media
          notify_user if options[:notify_user]
        end

        remove_ad_data if @status.ad?
        purge_cache

        @status.destroy! if @immediate
      else
        raise Mastodon::RaceConditionError
      end
    end
  end

  private

  def remove_from_self
    FeedManager.instance.unpush_from_home(@account, @status)
  end

  def remove_from_followers
    @account.followers_for_local_distribution.reorder(nil).find_each do |follower|
      FeedManager.instance.unpush_from_home(follower, @status)
    end
  end

  def remove_from_lists
    @account.lists_for_local_distribution.select(:id, :account_id).reorder(nil).find_each do |list|
      FeedManager.instance.unpush_from_list(list, @status)
    end
  end

  def remove_from_whale_list
    FeedManager.instance.remove_from_whale(@status)
  end

  def notify_user
    UserMailer.status_removed(@account.user, @status.id).deliver_later!
  end

  def remove_from_mentions
    # For limited visibility statuses, the mentions that determine
    # who receives them in their home feed are a subset of followers
    # and therefore the delete is already handled by sending it to all
    # followers. Here we send a delete to actively mentioned accounts
    # that may not follow the account

    @status.active_mentions.find_each do |mention|
      redis.publish("timeline:#{mention.account_id}", @payload)
    end
  end

  def signed_activity_json
    @signed_activity_json ||= Oj.dump(serialize_payload(@status, @status.reblog? ? ActivityPub::UndoAnnounceSerializer : ActivityPub::DeleteSerializer, signer: @account))
  end

  def remove_reblogs
    # We delete reblogs of the status before the original status,
    # because once original status is gone, reblogs will disappear
    # without us being able to do all the fancy stuff

    @status.reblogs.with_discarded.includes(:account).find_each do |reblog|
      RemoveStatusService.new.call(reblog, original_removed: true)
    end
  end

  def remove_from_hashtags
    @account.featured_tags.where(tag_id: @status.tags.map(&:id)).each do |featured_tag|
      featured_tag.decrement(@status.id)
    end

    return unless @status.public_visibility?

    @status.tags.map(&:name).each do |hashtag|
      redis.publish("timeline:hashtag:#{hashtag.mb_chars.downcase}", @payload)
      redis.publish("timeline:hashtag:#{hashtag.mb_chars.downcase}:local", @payload) if @status.local?
    end
  end

  def remove_from_group
    return unless @status.group_visibility?

    redis.publish("timeline:group:#{@status.group_id}", @payload)
  end

  def remove_media
    return if @options[:redraft] || !@immediate

    @status.media_attachments.destroy_all
  end

  def lock_options
    { redis: Redis.current, key: "distribute:#{@status.id}", autorelease: 5.minutes.seconds }
  end

  def send_to_bailey
    # Don't create job.  Bailey not cleaning up deletes at the moment.
  end

  def remove_user_interactions!
    if @status.reply? && @account.id != @status.in_reply_to_account_id
      InteractionsTracker.new(@account.id, @status.in_reply_to_account_id, :reply, @account.following?(@status.in_reply_to_account_id), @status.group).untrack
    elsif @status.quote? && @account.id != @status.quote.account_id
      InteractionsTracker.new(@account.id, @status.quote.account_id, :quote, @account.following?(@status.quote.account_id), @status.quote.group).untrack
    end
  end

  def remove_from_timeline_cache
    redis.del("sevro:#{@status.id}")
  end

  def remove_ad_data
    @status.preview_cards.each(&:destroy)
    @status.ad&.destroy
  end
end

def purge_cache
  purge_status(@status)
  Status.where(in_reply_to_id: @status.id).or(Status.where(quote_id: @status.id)).in_batches.each_record do |reply|
    purge_status(reply)
  end
end

def purge_status(status)
  Rails.cache.delete(status)
  InvalidateSecondaryCacheService.new.call('InvalidateStatusCacheWorker', status)
end
