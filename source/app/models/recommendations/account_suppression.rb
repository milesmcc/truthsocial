# frozen_string_literal: true

# == Schema Information
#
# Table name: recommendations.account_suppressions
#
#  account_id        :bigint(8)        not null, primary key
#  target_account_id :bigint(8)        not null, primary key
#  status_id         :bigint(8)        not null
#  created_at        :datetime         not null
#
class Recommendations::AccountSuppression < ApplicationRecord
  self.table_name = 'recommendations.account_suppressions'
  self.primary_keys = :account_id, :target_account_id

  belongs_to :account
  belongs_to :target_account, class_name: 'Account'
  belongs_to :status
end
