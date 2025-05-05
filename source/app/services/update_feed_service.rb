class UpdateFeedService
  attr_accessor :feed, :current_account, :feed_params, :account_feed_params

  def initialize(feed, current_account, update_params)
    @feed = feed
    @current_account = current_account
    @feed_params = update_params.extract!(:name, :description, :visibility)
    @account_feed_params = update_params.extract!(:pinned, :position)
  end

  def call
    create_default_account_feeds if current_account.account_feeds.blank?

    return if feed.following_feed? || feed.for_you_feed?

    account_feed = Feeds::AccountFeed.find_by(feed: feed, account: current_account)

    ApplicationRecord.transaction do
      feed.update!(feed_params) if feed.account == current_account && feed.custom_feed?

      position = account_feed_params[:position].to_i
      account_feed_params[:position] = [1, 2].include?(position) ? 3 : position unless position.zero?  # "For you" and "Following" feeds need to stay at the top
      account_feed.insert_at(account_feed_params[:position]) if account_feed_params[:position] && !position.zero?
      account_feed.update!(pinned: account_feed_params[:pinned]) unless account_feed_params[:pinned].nil?
    end
  end

  private

  def create_default_account_feeds
    Feeds::Feed.where.not(feed_type: 'custom').ordered_for_you.each.with_index(1) do |feed, index|
      current_account.account_feeds.create!(feed_id: feed.feed_id, pinned: true, position: index)
    end
  end
end
