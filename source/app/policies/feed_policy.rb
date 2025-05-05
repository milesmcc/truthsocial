# frozen_string_literal: true

class FeedPolicy < ApplicationPolicy
  def show?
    feed_creator? || public_feed?
  end

  def update?
    feed_creator? || default_feed?
  end

  def destroy?
    feed_creator? || feed_subscriber?
  end

  def seen?
    feed_creator? || feed_subscriber? || default_feed?
  end

  private

  def feed_creator?
    record.created_by_account_id == current_account&.id
  end

  def public_feed?
    record.public_feed?
  end

  def feed_subscriber?
    record.account_feeds.exists?(account: current_account)
  end

  def default_feed?
    !record.custom_feed?
  end
end
