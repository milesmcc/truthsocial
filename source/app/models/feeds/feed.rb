# frozen_string_literal: true

# == Schema Information
#
# Table name: feeds.feeds
#
#  feed_id               :bigint(8)        not null, primary key
#  name                  :text             not null
#  description           :text             not null
#  created_by_account_id :bigint(8)        not null
#  visibility            :enum             default("private"), not null
#  feed_type             :enum             default("custom"), not null
#  created_at            :datetime         not null
#
class Feeds::Feed < ApplicationRecord
  self.table_name = 'feeds.feeds'
  self.primary_key = :feed_id
  has_many :account_feeds
  has_many :feed_accounts
  belongs_to :account, foreign_key: 'created_by_account_id'

  enum visibility: { public: 'public', private: 'private' }, _suffix: :feed
  enum feed_type: { following: 'following', for_you: 'for_you', groups: 'groups', custom: 'custom' }, _suffix: :feed

  validates :name, presence: true, length: { minimum: 1, maximum: ENV.fetch('MAX_FEED_NAME_CHARS', 25).to_i }
  validates :description, length: { maximum: ENV.fetch('MAX_FEED_DESCRIPTION_CHARS', 70).to_i }

  validates_with FeedValidator, on: :create

  after_commit :dispatch_event

  scope :ordered_for_you, -> { order(Arel.sql('(case feeds.feed_id when 2 then 1 when 1 then 2 when 3 then 3 end)')) }

  PROTO_MAPPING = {
    name: 2,
    description: 3,
    visibility: 4,
  }

  class << self
    def account_feeds_map(feed_ids, account_id)
      Feeds::AccountFeed.where(feed_id: feed_ids, account_id: account_id)
                        .each_with_object({}) do |account_feed, hash|
                          hash[account_feed.feed_id] = account_feed
                        end
    end
  end

  private

  def dispatch_event
    type = if callback_action?(:create)
             'feed.created'
           elsif callback_action?(:update)
             'feed.updated'
           elsif callback_action?(:destroy)
             'feed.deleted'
           end

    EventProvider::EventProvider.new(type, ::FeedEvent, self, fields_changed(self)).call
  end

  def fields_changed(feed)
    updatable_fields = %w(name description visibility)
    changed_fields = feed.saved_changes.keys
    updated_fields = changed_fields.select { |f| updatable_fields.include?(f) }.map(&:to_sym)
    updated_fields.map { |field| PROTO_MAPPING[field] }
  end

  def callback_action?(action)
    transaction_include_any_action?([action])
  end
end
