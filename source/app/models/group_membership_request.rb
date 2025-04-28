# == Schema Information
#
# Table name: group_membership_requests
#
#  id         :bigint(8)        not null, primary key
#  account_id :bigint(8)        not null
#  group_id   :bigint(8)        not null
#  created_at :datetime         not null
#
class GroupMembershipRequest < ApplicationRecord
  include Paginable
  include GroupRelationshipCacheable

  belongs_to :group
  belongs_to :account

  scope :without_suspended, -> { joins(:account).merge(Account.without_suspended) }

  def authorize!
    group.memberships.create!(account: account)
    destroy!
  end

  alias reject! destroy!

  def object_type
    :group_request
  end
end
