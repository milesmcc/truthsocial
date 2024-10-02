# frozen_string_literal: true

class DestroyGroupService
  include GroupCachable

  def initialize(account:, group:)
    @account = account
    @group = group
  end

  def call
    group.discard
    group.group_suggestion&.destroy
    GroupDeletionNotifyWorker.perform_async(group.id)
    invalidate_group_caches(account, group)
  end

  private

  attr_accessor :account, :group
end
