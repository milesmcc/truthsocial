# frozen_string_literal: true

class REST::FeedSerializer < Panko::Serializer
  include RoutingHelper

  attributes :id,
             :name,
             :description,
             :visibility,
             :created_by_account_id,
             :pinned,
             :seen,
             :feed_type,
             :can_unpin,
             :can_delete,
             :can_sort,
             :created_at

  def id
    return feed_id if default_feed?

    object.id.to_s
  end

  def created_by_account_id
    return context[:current_account].id.to_s if default_feed?

    object.created_by_account_id.to_s
  end

  def pinned
    return true if default_feed? && context[:relationships].account_feeds[object.id].nil?

    context[:relationships].account_feeds[object.id]&.pinned # Currently a user won't have an account_feed record for a public feed if they are not the creator
  end

  def seen
    context[:relationships].seen_feeds[object.id]
  end

  def can_unpin
    unlocked_feed?
  end

  def can_delete
    default_feed? ? false : true
  end

  def can_sort
    unlocked_feed?
  end

  private

  def feed_id
    object.for_you_feed? ? 'recommended' : object.feed_type
  end

  def unlocked_feed?
    !(following_feed? || object.for_you_feed?)
  end

  def following_feed?
    object.following_feed?
  end

  def default_feed?
    %w(following for_you groups).include? object.feed_type
  end
end
