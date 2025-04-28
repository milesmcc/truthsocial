# frozen_string_literal: true

class AccountFeedValidator < ActiveModel::Validator
  def validate(account_feed)
    account_feed.errors.add(:base, I18n.t('feeds.errors.too_many_pinned')) if pinning?(account_feed) && pinned_limit_reached?(account_feed)
  end

  private

  def pinning?(account_feed)
    account_feed.pinned_changed? && account_feed.pinned == true
  end

  def pinned_limit_reached?(account_feed)
    feed_count = Feeds::AccountFeed.where(account_id: account_feed.account_id, pinned: true).size
    max_allowed = ENV.fetch('MAX_FEED_PINNED_ALLOWED', 6).to_i

    feed_count >= max_allowed
  end
end
