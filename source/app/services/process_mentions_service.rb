# frozen_string_literal: true

class ProcessMentionsService < BaseService
  include Payloadable
  include Redisable

  MAX_MENTIONS = ENV.fetch('MAX_MENTIONS', 15).to_i
  NOTIFICATIONS_TRESHOLD = 100
  MENTION_MISMATCH_EXPIRE_AFTER = 7.days.seconds

  # Scan status for mentions and fetch remote mentioned users, create
  # local mention pointers, send Salmon notifications to mentioned
  # remote users
  # @param [Status] status
  # @param [Enumerable] mentions an array of usernames
  # @param [Status] thread in_reply_to status
  def call(status, mentions, thread = nil)
    @passed_mentions = mentions
    @status = status
    @status_mentions = scan_mentions(@status).map(&:downcase)
    @thread = thread
    mention_notifications = []

    if @status.reply?
      previous_mentioned_usernames = Account.joins(:mentions).where('mentions.status_id = ?', @thread.id).pluck(:username)
      @previously_mentioned = (previous_mentioned_usernames << @thread.account.username).map(&:downcase)
    end

    group = @status.group_visibility?.presence && @status.group
    mentions = mentions.first(MAX_MENTIONS) if mentions.length > MAX_MENTIONS
    mentioned_accounts = Account.ci_find_by_usernames(mentions)
    accounts_with_mention_preference = mentioned_accounts.where(receive_only_follow_mentions: true)
    if accounts_with_mention_preference.any?
      followers = Follow.where(account: accounts_with_mention_preference, target_account: @status.account).pluck(:account_id)
    end

    mentioned_accounts.each do |acc|
      next acc if mention_undeliverable?(acc) || acc.suspended?

      reject_missing_status_mention(acc.username.downcase)
      # Since mentions are currently tied to audience and notifications, skip mentions
      # of non-members if private group
      next acc if (group&.members_only? && !group.members&.where(id: acc.id)&.exists?) || skip_new_account_mentions(acc)

      next acc if acc.receive_only_follow_mentions && !followers.include?(acc.id)

      new_mention = acc.mentions.new(status: status)
      mention_notifications << new_mention if new_mention.save
    end

    mention_notifications
  end

  def self.create_notification(status, mention)
    mentioned_account = mention.account
    type = status.group ? :group_mention : :mention

    if status.account.followers_count < NOTIFICATIONS_TRESHOLD
      ProcessMentionNotificationsWorker.perform_in(61.seconds, status.id, mention.id, type.to_sym)
    else
      LocalNotificationWorker.perform_async(mentioned_account.id, mention.id, mention.class.name, type.to_sym)
    end
  end

  private

  def mention_undeliverable?(mentioned_account)
    mentioned_account.nil? || (!mentioned_account.local? && mentioned_account.ostatus?)
  end

  def scan_mentions(status)
    status.text.scan(Account::MENTION_RE).map(&:second).map(&:downcase)
  end

  def reject_missing_status_mention(username)
    return if @status_mentions.include? username

    if (quote = @status.quote?)
      return if username == quote.account.username.downcase
    elsif @status.reply?
      return if @previously_mentioned.include? username
    end

    Rails.logger.info "mention_mismatch #{@status.account_id} thread_id: #{@thread&.id} reply_text: #{@status.text} passed_mentions: #{@passed_mentions} previously_mentioned: #{@previously_mentioned}"

    redis_key = "mention_mismatch:#{DateTime.current.to_date}"
    redis_element_key = @status.account_id
    redis.zincrby(redis_key, 1, redis_element_key)
    redis.expire(redis_key, MENTION_MISMATCH_EXPIRE_AFTER)

    raise Mastodon::ValidationError, I18n.t('statuses.errors.mention_mismatch')
  end

  def skip_new_account_mentions(acc)
    return false if (Time.now - @status.account.created_at).round > 7.days
    !@status.reply? || (@status.reply? && !@previously_mentioned.include?(acc.username.downcase))
  end
end
