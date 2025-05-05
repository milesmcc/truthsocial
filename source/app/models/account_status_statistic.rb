# frozen_string_literal: true

# == Schema Information
#
# Table name: mastodon_api.account_status_statistics
#
#  account_id               :bigint(8)        primary key
#  statuses_count           :integer
#  last_status_at           :datetime
#  last_following_status_at :datetime
#
class AccountStatusStatistic < ApplicationRecord
  self.table_name = 'mastodon_api.account_status_statistics'
  self.primary_key = :account_id

  belongs_to :account
end
