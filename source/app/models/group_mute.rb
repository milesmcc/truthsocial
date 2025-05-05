# == Schema Information
#
# Table name: group_mutes
#
#  account_id :bigint(8)        not null, primary key
#  group_id   :bigint(8)        not null, primary key
#
class GroupMute < ApplicationRecord
  include GroupRelationshipCacheable

  self.primary_keys = :account_id, :group_id
  belongs_to :account
  belongs_to :group
end
