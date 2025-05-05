# frozen_string_literal: true

class Api::V1::FeedsController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :read, :'read:feeds' }, only: [:index, :show]
  before_action -> { doorkeeper_authorize! :write, :'write:feeds' }, only: [:create, :update, :destroy, :add_account, :remove_account, :seen]
  before_action :require_user!
  before_action :set_feeds, only: [:index]
  before_action :set_feed, only: [:show, :update, :destroy, :add_account, :remove_account, :seen]
  before_action :set_account, only: [:add_account, :remove_account]

  DEFAULT_FEEDS_SIZE = 18

  def index
    render json: Panko::ArraySerializer.new(@feeds, each_serializer: REST::FeedSerializer, context: { current_account: current_account, relationships: relationships(@feeds) }).to_json
  end

  def create
    @feed = Feeds::Feed.new(feed_create_params)
    @feed.account = current_account

    ApplicationRecord.transaction do
      create_default_account_feeds if current_account.account_feeds.blank?
      @feed.save!
      @feed.account_feeds.create!(account: current_account, position: set_position)
    end

    render json: REST::FeedSerializer.new(context: { current_account: current_account, relationships: relationships([@feed]) }).serialize(@feed)
  end

  def show
    begin
      authorize @feed, :show?, policy_class: FeedPolicy
    rescue Mastodon::NotPermittedError
      raise ActiveRecord::RecordNotFound
    end

    render json: REST::FeedSerializer.new(context: { current_account: current_account, relationships: relationships([@feed]) }).serialize(@feed)
  end

  def update
    begin
      authorize @feed, :update?, policy_class: FeedPolicy
    rescue Mastodon::NotPermittedError
      raise ActiveRecord::RecordNotFound
    end

    UpdateFeedService.new(@feed, current_account, feed_update_params).call
    render json: REST::FeedSerializer.new(context: { current_account: current_account, relationships: relationships([@feed]) }).serialize(@feed)
  end

  def destroy
    begin
      authorize @feed, :destroy?, policy_class: FeedPolicy
    rescue Mastodon::NotPermittedError
      raise ActiveRecord::RecordNotFound
    end

    feed_creator? ? @feed.destroy : @feed.account_feeds.destroy_by(account: current_account)
  end

  def seen
    begin
      authorize @feed, :seen?, policy_class: FeedPolicy
    rescue Mastodon::NotPermittedError
      raise ActiveRecord::RecordNotFound
    end

    key = "seen_feeds:#{current_account.id}"
    redis.hset(key, @feed.id, Time.now.utc.to_i)
    redis.expire(key, 1.month.seconds)
    InvalidateSecondaryCacheService.new.call('SyncSeenFeedsWorker', current_account.id, @feed.id)
  end

  def add_account
    begin
      authorize @feed, :update?, policy_class: FeedPolicy
    rescue Mastodon::NotPermittedError
      raise ActiveRecord::RecordNotFound
    end

    @feed.feed_accounts.create(account: @account)
  end

  def remove_account
    begin
      authorize @feed, :update?, policy_class: FeedPolicy
    rescue Mastodon::NotPermittedError
      raise ActiveRecord::RecordNotFound
    end

    @feed.feed_accounts.find_by(account: @account)&.destroy
  end

  private

  def feed_create_params
    params.permit(:name, :description, :visibility)
  end

  def feed_update_params
    params.permit(:name, :description, :visibility, :pinned, :sort, :position)
  end

  def set_feeds
    @feeds = current_account.feeds.order(:position).limit(DEFAULT_FEEDS_SIZE)
    @feeds = @feeds.reject(&:for_you_feed?) # remove once for_you is supported
    @feeds = Feeds::Feed.where(feed_type: %w(following groups)) if @feeds.blank? || exclude_custom_feeds?
  end

  def set_feed
    @feed = params[:id].to_i.zero? ? Feeds::Feed.find_by!(feed_type: params[:id]) : Feeds::Feed.find(params[:id])
  rescue ActiveRecord::StatementInvalid
    raise ActiveRecord::RecordNotFound
  end

  def set_account
    @account = Account.find(params[:account_id])
  end

  def set_position
    Feeds::AccountFeed.where(account: current_account).size + 1
  end

  def feed_creator?
    @feed.created_by_account_id == current_account&.id
  end

  # We only want to create these records for users that are using the Feeds feature.
  # If we decide against this, then we can create these records when 'feeds_onboarded' is set to true.
  def create_default_account_feeds
    Feeds::Feed.where.not(feed_type: 'custom').ordered_for_you.each.with_index(1) do |feed, index|
      Feeds::AccountFeed.create!(feed_id: feed.feed_id, account_id: current_account.id, pinned: true, position: index)
    end
  end

  def relationships(feeds)
    FeedRelationshipsPresenter.new(feeds, current_account)
  end

  def exclude_custom_feeds?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('DISABLE_CUSTOM_FEEDS', false))
  end
end
