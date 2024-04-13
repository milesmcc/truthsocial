# frozen_string_literal: true

class DisabledUserRefollowService < BaseService
  include Payloadable
  include AppAttestable

  attr_reader :source_account

  # Refollow all accounts followed by a disabled user (using the account!)
  # and remove from follow_deletes table
  # @param [Account] source_account Where to unfollow from
  def call(account)
    @source_account = account

    refollow!
  end

  private

  def refollow!
    following_deletes = FollowDelete.where(account_id: source_account.id)
    follower_deletes = FollowDelete.where(target_account_id: source_account.id)
    (follower_deletes + following_deletes).each do |fd|
      FollowService.new.call(fd.account, fd.target_account, skip_notification: true)
      FollowDelete.destroy_by(account: fd.account, target_account: fd.target_account)
    rescue => e
      alert(e.inspect, true, 'Refollow error')
      next
    end
  end
end
