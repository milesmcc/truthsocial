# frozen_string_literal: true

class FeedValidator < ActiveModel::Validator
  def validate(feed)
    feed.errors.add(:base, I18n.t('feeds.errors.feed_creation_limit')) if limit_reached?(feed)
  end

  private

  def limit_reached?(feed)
    feed_count = Feeds::Feed.where(created_by_account_id: feed.created_by_account_id).size
    max_allowed = ENV.fetch('MAX_FEED_CREATIONS_ALLOWED', 15).to_i

    feed_count >= max_allowed
  end
end
