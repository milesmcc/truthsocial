# frozen_string_literal: true

# == Schema Information
#
# Table name: feeds.account_feeds
#
#  account_feed_id :bigint(8)        not null, primary key
#  account_id      :bigint(8)        not null
#  feed_id         :bigint(8)        not null
#  pinned          :boolean          default(FALSE), not null
#  position        :integer          not null
#  created_at      :datetime         not null
#
class Feeds::AccountFeed < ApplicationRecord
  self.table_name = 'feeds.account_feeds'
  self.primary_key = :account_feed_id
  belongs_to :feed, class_name: 'Feeds::Feed', foreign_key: 'feed_id'
  belongs_to :account
  validates :position, uniqueness: { scope: [:feed_id, :account_id] }

  acts_as_list sequential_updates: true, scope: [:account_id]

  validates_with AccountFeedValidator, on: :update
end
