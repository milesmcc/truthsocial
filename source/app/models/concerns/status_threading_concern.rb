# frozen_string_literal: true

module StatusThreadingConcern
  extend ActiveSupport::Concern

  def ancestors(limit, account = nil)
    StatusRepliesV1.new(self).ancestors(limit, account)
  end

  def descendants(limit, account = nil, offset = 0, max_child_id = nil, since_child_id = nil, depth = nil)
    StatusRepliesV1.new(self).descendants(limit, account, offset, max_child_id, since_child_id, depth)
  end

  def self_replies(limit)
    account.statuses.where(in_reply_to_id: id, visibility: [:public, :unlisted]).reorder(id: :asc).limit(limit)
  end
end
