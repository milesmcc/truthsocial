# frozen_string_literal: true

class SuspendAccountService < BaseService
  include Payloadable

  def call(account)
    @account = account

    suspend!
    reject_remote_follows!
    unmerge_from_home_timelines!
    unmerge_from_list_timelines!
    Admin::MediaPrivatizationWorker.perform_async(account.id)
  end

  private

  def suspend!
    @account.suspend! unless @account.suspended?
  end

  def reject_remote_follows!
    return if @account.local? || !@account.activitypub?

    # When suspending a remote account, the account obviously doesn't
    # actually become suspended on its origin server, i.e. unlike a
    # locally suspended account it continues to have access to its home
    # feed and other content. To prevent it from being able to continue
    # to access toots it would receive because it follows local accounts,
    # we have to force it to unfollow them. Unfortunately, there is no
    # counterpart to this operation, i.e. you can't then force a remote
    # account to re-follow you, so this part is not reversible.

    follows = Follow.where(account: @account).to_a

    ActivityPub::DeliveryWorker.push_bulk(follows) do |follow|
      [Oj.dump(serialize_payload(follow, ActivityPub::RejectFollowSerializer)), follow.target_account_id, @account.inbox_url]
    end

    follows.each(&:destroy)
  end

  def distribute_update_actor!
    return unless @account.local?

    account_reach_finder = AccountReachFinder.new(@account)

    ActivityPub::DeliveryWorker.push_bulk(account_reach_finder.inboxes) do |inbox_url|
      [signed_activity_json, @account.id, inbox_url]
    end
  end

  def unmerge_from_home_timelines!
    @account.followers_for_local_distribution.find_each do |follower|
      FeedManager.instance.unmerge_from_home(@account, follower)
    end
  end

  def unmerge_from_list_timelines!
    @account.lists_for_local_distribution.find_each do |list|
      FeedManager.instance.unmerge_from_list(@account, list)
    end
  end

  def signed_activity_json
    @signed_activity_json ||= Oj.dump(serialize_payload(@account, ActivityPub::UpdateSerializer, signer: @account))
  end
end
