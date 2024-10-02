# frozen_string_literal: true

class Mobile::MarketingNotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'push', retry: 5

  TTL     = 8.hours.to_s
  URGENCY = 'normal'
  IOS_PLATFORM = 1
  ANDROID_PLATFORM = 2

  def self.queue_notifications(message:, url:, mark_id: nil)
    tester_platform = IOS_PLATFORM
    tester_user_ids = if mark_id.present?
                        ENV.fetch('MARK_ID_PUSH_NOTIFICATIONS_USER_IDS', '')
                           .split(',')
                           .map(&:to_i)
                           .reject(&:zero?)
                      end

    if tester_user_ids.present?
      tester_tokens = MarketingPushSubscription
                      .select(:device_token)
                      .distinct
                      .joins('inner join users on users.id = web_push_subscriptions.user_id')
                      .where(users: { approved: true, disabled: false, id: tester_user_ids }, platform: tester_platform)
                      .where.not(device_token: nil)
                      .to_a
                      .pluck(:device_token)
      perform_async(tester_tokens, message, url, tester_platform, mark_id)
    end

    [IOS_PLATFORM, ANDROID_PLATFORM].each do |platform|
      tokens = MarketingPushSubscription
               .select(:device_token)
               .distinct
               .joins('inner join users on users.id = web_push_subscriptions.user_id')
               .where(users: { approved: true, disabled: false }, platform: platform)
               .where.not(device_token: nil)
      tokens = tokens.where.not(users: { id: tester_user_ids }) if platform == tester_platform && tester_user_ids.present?
      tokens.find_in_batches(batch_size: 2_000) do |batch|
        perform_async(batch.pluck(:device_token), message, url, platform, nil)
      end
    end
  end

  def perform(tokens, message, url, platform, mark_id)
    endpoint = ENV.fetch('MOBILE_NOTIFICATION_ENDPOINT')
    extend   = [{ key: 'truthLink', val: url }, { key: 'category', val: 'marketing' }]
    extend.push({ key: 'markId', val: mark_id }) if mark_id.present?
    msg      = { token: tokens, category: 'invite', platform: platform, message: message, extend: extend }
    msg[:mutable_content] = true if platform == IOS_PLATFORM
    body     = { 'notifications' => [msg] }.to_json

    return unless endpoint.present? && tokens.any? && message && url

    request_pool.with(Addressable::URI.parse(endpoint).normalized_site) do |http_client|
      request = Request.new(:post, endpoint, body: body, http_client: http_client)
      request.add_headers('Content-Type' => 'application/octet-stream')
      request.perform do |response|
        raise Mastodon::UnexpectedResponseError, response unless (200...300).cover?(response.code)
      end
    end
  rescue ActiveRecord::RecordNotFound
    true
  end

  private

  def request_pool
    RequestPool.current
  end
end

class MarketingPushSubscription < ApplicationRecord
  self.table_name = 'web_push_subscriptions'
  self.primary_key = :device_token
end
