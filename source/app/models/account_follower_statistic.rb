# frozen_string_literal: true

# == Schema Information
#
# Table name: mastodon_api.account_follower_statistics
#
#  account_id      :bigint(8)        primary key
#  followers_count :integer
#
class AccountFollowerStatistic < ApplicationRecord
  self.table_name = 'mastodon_api.account_follower_statistics'
  self.primary_key = :account_id

  belongs_to :account
end
