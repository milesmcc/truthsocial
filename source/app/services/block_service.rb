# frozen_string_literal: true

class BlockService < BaseService
  include Payloadable

  def call(account, target_account)
    return if account.id == target_account.id

    if account.following?(target_account)
      UnfollowService.new.call(account, target_account)
      FollowDelete.where(account_id: account.id).destroy_all
    end

    if target_account.following?(account)
      UnfollowService.new.call(target_account, account)
      FollowDelete.where(target_account_id: target_account).destroy_all
    end

    RejectFollowService.new.call(target_account, account) if target_account.requested?(account)

    block = account.block!(target_account)
    invalidate_secondary_caches(account, target_account)
    BlockWorker.perform_async(account.id, target_account.id)
    create_notification(block) if !target_account.local? && target_account.activitypub?
    export_prometheus_metric
    block
  end

  private

  def invalidate_secondary_caches(account, target_account)
    InvalidateSecondaryCacheService.new.call("InvalidateFollowCacheWorker", account.id, target_account.id, target_account.whale?)
    InvalidateSecondaryCacheService.new.call("InvalidateFollowCacheWorker", target_account.id, account.id, account.whale?)
  end

  def create_notification(block)
    ActivityPub::DeliveryWorker.perform_async(build_json(block), block.account_id, block.target_account.inbox_url)
  end

  def build_json(block)
    Oj.dump(serialize_payload(block, ActivityPub::BlockSerializer))
  end

  def export_prometheus_metric
    Prometheus::ApplicationExporter::increment(:blocks)
  end
end
