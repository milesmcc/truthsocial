# frozen_string_literal: true

class ProcessMentionsService < BaseService
  include Payloadable

  MAX_MENTIONS = ENV.fetch('MAX_MENTIONS', 15).to_i

  # Scan status for mentions and fetch remote mentioned users, create
  # local mention pointers, send Salmon notifications to mentioned
  # remote users
  # @param [Status] status
  # @param [Enumerable] mentions an array of usernames
  def call(status, mentions)
    @status = status

    mentions = mentions.first(MAX_MENTIONS) if mentions.length > MAX_MENTIONS

    mentioned_accounts = Account.ci_find_by_usernames(mentions)
    mentioned_accounts.each do |acc|
      next acc if mention_undeliverable?(acc) || acc.suspended?

      new_mention = acc.mentions.new(status: status)
      create_notification(new_mention) if new_mention.save
    end
  end

  private

  def mention_undeliverable?(mentioned_account)
    mentioned_account.nil? || (!mentioned_account.local? && mentioned_account.ostatus?)
  end

  def create_notification(mention)
    mentioned_account = mention.account

    if mentioned_account.local?
      LocalNotificationWorker.perform_async(mentioned_account.id, mention.id, mention.class.name, :mention)
    elsif mentioned_account.activitypub?
      ActivityPub::DeliveryWorker.perform_async(activitypub_json, mention.status.account_id, mentioned_account.inbox_url, { synchronize_followers: !mention.status.distributable? })
    end
  end

  def activitypub_json
    return @activitypub_json if defined?(@activitypub_json)
    @activitypub_json = Oj.dump(serialize_payload(ActivityPub::ActivityPresenter.from_status(@status), ActivityPub::ActivitySerializer, signer: @status.account))
  end

  def resolve_account_service
    ResolveAccountService.new
  end
end
