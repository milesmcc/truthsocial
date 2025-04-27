# frozen_string_literal: true

# == Schema Information
#
# Table name: mastodon_api.account_following_statistics
#
#  account_id      :bigint(8)        primary key
#  following_count :integer
#
class AccountFollowingStatistic < ApplicationRecord
  self.table_name = 'mastodon_api.account_following_statistics'
  self.primary_key = :account_id

  belongs_to :account
end
