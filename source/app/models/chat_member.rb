# == Schema Information
#
# Table name: api.chat_members
#
#  chat_id                        :integer          primary key
#  account_id                     :bigint(8)        primary key
#  accepted                       :boolean          default(FALSE)
#  active                         :boolean          default(TRUE)
#  silenced                       :boolean          default(FALSE)
#  latest_read_message_created_at :datetime
#  unread_messages_count          :integer
#  other_member_account_ids       :bigint(8)        is an Array
#  latest_message_at              :datetime
#  latest_message_id              :bigint(8)
#  latest_activity_at             :datetime
#  blocked                        :boolean
#  other_member_username          :text
#
class ChatMember < ApplicationRecord
  self.table_name = 'api.chat_members'
  self.primary_keys = :chat_id, :account_id
  belongs_to :chat
end
