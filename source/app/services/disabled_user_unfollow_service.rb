# frozen_string_literal: true

class DisabledUserUnfollowService < BaseService
  include Payloadable
  include Redisable

  FOLLOW_DELETE_FIELDS = %w(account_id target_account_id).freeze

  attr_reader :source_account

  # Unfollow all accounts followed by a disabled user (using the account!)
  # and sweep records into follow_deletes table for restoration if necessary
  # @param [Account] source_account Where to unfollow from
  def call(account)
    @source_account = account
    return if @source_account.user.enabled?
    unfollow!
  end

  private

  def unfollow!
    scope = Follow.joins(:target_account).where(account_id: source_account.id)

    follows_whales = scope.where('accounts.whale').exists?
    target_accounts_id_whale = scope.pluck(:target_account_id, :whale)

    Follow.transaction do
      following = Follow.where(account_id: source_account.id)
      followers = Follow.where(target_account_id: source_account.id)
      (following + followers).each do |f|
        FollowDelete.create!(account_id: f.account_id, target_account_id: f.target_account_id)
      end

      following.destroy_all
      followers.destroy_all
    end

    redis.del("whale:following:#{@source_account.id}") if follows_whales

    target_accounts_id_whale.each do |a|
      InvalidateSecondaryCacheService.new.call("InvalidateFollowCacheWorker", source_account.id, a[0], a[1])
    end
  end
end
