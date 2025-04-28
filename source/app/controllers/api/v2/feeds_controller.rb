# frozen_string_literal: true

class Api::V2::FeedsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:feeds' }, only: [:index]
  before_action :require_user!
  before_action :enable_feature_flag, only: [:index]
  before_action :set_feeds, only: [:index]

  DEFAULT_FEEDS_SIZE = 18
  FOR_YOU_REQUIRED_IOS_VERSION = ENV.fetch('FOR_YOU_REQUIRED_IOS_VERSION', 0).to_i
  FOR_YOU_REQUIRED_ANDROID_VERSION = ENV.fetch('FOR_YOU_REQUIRED_ANDROID_VERSION', 0).to_i

  def index
    render json: Panko::ArraySerializer.new(@feeds, each_serializer: REST::FeedSerializer, context: { current_account: current_account, relationships: relationships(@feeds) }).to_json
  end

  private

  def set_feeds
    @feeds = current_account.feeds.order(:position).limit(DEFAULT_FEEDS_SIZE)
    @feeds = Feeds::Feed.where(feed_type: %w(following for_you groups)).ordered_for_you if @feeds.blank? || exclude_custom_feeds?
    @feeds = @feeds.reject(&:for_you_feed?) unless current_account.for_you_enabled?
  end

  def relationships(feeds)
    FeedRelationshipsPresenter.new(feeds, current_account)
  end

  def exclude_custom_feeds?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('DISABLE_CUSTOM_FEEDS', false))
  end

  def enable_feature_flag
    return if !required_ios_version && !required_android_version
    ::Configuration::AccountEnabledFeature.upsert(
      account_id: current_account.id,
      feature_flag_id: 2,
    )
  end

  def required_ios_version
    ios_version = request&.user_agent&.strip&.match(/^TruthSocial\/(\d+) .+/) || []
    !ios_version[1].nil? && !FOR_YOU_REQUIRED_IOS_VERSION.zero?  && ios_version[1].to_i >= FOR_YOU_REQUIRED_IOS_VERSION
  end

  def required_android_version
    android_version = request&.user_agent&.strip&.match(/^TruthSocialAndroid\/okhttp\/.+\/(\d+)/) || []
    !android_version[1].nil? && !FOR_YOU_REQUIRED_ANDROID_VERSION.zero? && android_version[1].to_i >= FOR_YOU_REQUIRED_ANDROID_VERSION
  end
end
