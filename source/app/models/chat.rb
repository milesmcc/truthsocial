# == Schema Information
#
# Table name: api.chats
#
#  chat_id            :integer          primary key
#  owner_account_id   :bigint(8)
#  created_at         :datetime
#  message_expiration :interval         default(14 days)
#  chat_type          :enum
#  members            :bigint(8)        is an Array
#
class Chat < ApplicationRecord
  attribute :message_expiration, :interval
  self.table_name = 'api.chats'
  self.primary_key = :chat_id
  self.record_timestamps = false

  has_many :chat_members
  has_many :chat_messages

  scope :with_member, -> { joins(:chat_members).select('chat_members.*', 'chats.*') }
  scope :account_belongs_to, -> { joins(:chat_members).select('chat_members.*', 'chats.*').where(chat_members: { active: true }) }
  scope :has_account_like, -> (query) { query ? where('other_member_username ILIKE ?', "#{query}%") : all }
  scope :ordered, -> { order('latest_activity_at DESC') }

  include Paginable

  class << self
    def paginate_by_ordered_max_id(limit, max_id = nil, since_id = nil, account_id)
      query = limit(limit)

      if (max_id.present? || since_id.present?) && (chat_member = ChatMember.find([max_id.present? ? max_id : since_id, account_id]))
        query = query.where('latest_activity_at < ?', chat_member.latest_activity_at) if max_id.present?
        query = query.where('latest_activity_at > ?', chat_member.latest_activity_at) if since_id.present?
      end

      query
    end

    def paginate_by_max_id(limit, max_id = nil, since_id = nil)
      query = order(arel_table[:chat_id].desc).limit(limit)
      query = query.where(arel_table[:chat_id].lt(max_id)) if max_id.present?
      query = query.where(arel_table[:chat_id].gt(since_id)) if since_id.present?
      query
    end
  end

  def channel?
    self.chat_type == 'channel'
  end
end
