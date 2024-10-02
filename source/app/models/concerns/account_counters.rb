# frozen_string_literal: true

module AccountCounters
  extend ActiveSupport::Concern

  included do
    has_one :account_follower, class_name: AccountFollowerStatistic.name, inverse_of: :account
    has_one :account_following, class_name: AccountFollowingStatistic.name, inverse_of: :account
    has_one :account_status, class_name: AccountStatusStatistic.name, inverse_of: :account

  end

  def followers_count
    account_follower&.followers_count || 0
  end

  def following_count
    account_following&.following_count || 0
  end

  def statuses_count
    account_status&.statuses_count || 0
  end

  def last_status_at
    account_status&.last_status_at
  end

  def last_following_status_at
    account_status&.last_following_status_at
  end
end
