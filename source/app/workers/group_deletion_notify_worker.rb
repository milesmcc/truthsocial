# frozen_string_literal: true

class GroupDeletionNotifyWorker
  include Sidekiq::Worker

  def perform(group_id)
    group = Group.find(group_id)

    group.members.find_each do |member|
      NotifyService.new.call(member, :group_delete, group)
    end
  rescue ActiveRecord::RecordNotFound
    true
  end
end
