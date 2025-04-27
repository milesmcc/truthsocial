# frozen_string_literal: true

# == Schema Information
#
# Table name: recommendations.group_suppressions
#
#  account_id :bigint(8)        not null, primary key
#  group_id   :bigint(8)        not null, primary key
#  status_id  :bigint(8)        not null
#  created_at :datetime         not null
#
class Recommendations::GroupSuppression < ApplicationRecord
  self.table_name = 'recommendations.group_suppressions'
  self.primary_keys = :account_id, :group_id

  belongs_to :account
  belongs_to :group
  belongs_to :status
end
