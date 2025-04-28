# == Schema Information
#
# Table name: api.chat_member_removals
#
#  chat_id      :integer          primary key
#  account_id   :bigint(8)        primary key
#  removed_at   :datetime
#  removal_type :enum
#
class ChatMemberRemoval < ApplicationRecord
  self.table_name = 'api.chat_member_removals'
  self.primary_keys = :chat_id, :account_id

  class << self
    def paginate_by_time(limit, to = nil, from = nil)
      query = limit(limit)

      if to.present?
        query = query.where('removed_at < ?', Time.at(to.to_i - 1))
      end

      if from.present?
        query = query.where('removed_at > ?', Time.at(from.to_i + 1))
      end

      query
    end
  end
end
