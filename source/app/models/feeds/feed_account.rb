# frozen_string_literal: true

# == Schema Information
#
# Table name: feeds.feed_accounts
#
#  feed_id    :bigint(8)        not null, primary key
#  account_id :bigint(8)        not null, primary key
#  created_at :datetime         not null
#
class Feeds::FeedAccount < ApplicationRecord
  self.table_name = 'feeds.feed_accounts'
  self.primary_keys = :feed_id, :account_id
  belongs_to :account
  belongs_to :feed, class_name: 'Feeds::Feed', foreign_key: 'feed_id'
end
