# frozen_string_literal: true

class TvProgramReminderNotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'push', retry: 5

  TTL     = 8.hours.to_s
  URGENCY = 'normal'
  WEB_PLATFORM = 0
  IOS_PLATFORM = 1
  ANDROID_PLATFORM = 2

  def perform(channel_id, start_time)
    date_start_time = Time.zone.at(start_time.to_i / 1000).to_datetime
    tv_program = TvProgram.where(channel_id: channel_id).where(start_time: date_start_time).first
    program_status = tv_program.status

    return unless program_status && tv_program


    url = program_status.uri
    message = "#{tv_program.name} has started on #{tv_program.tv_channel.name}."

    [IOS_PLATFORM, ANDROID_PLATFORM].each do |platform|
      tokens = MarketingPushSubscription.
      select(:device_token).
      distinct.
      joins("inner join users on users.id = web_push_subscriptions.user_id
             inner join accounts on users.account_id = accounts.id
             inner join tv.reminders on tv.reminders.account_id = accounts.id").
      where("tv.reminders": {channel_id: channel_id, start_time: date_start_time}, users: { approved: true, disabled: false }, platform: platform).
      where.not(device_token: nil)

      tokens.find_in_batches(batch_size: 2_000) do |batch|
        send_notification(batch.pluck(:device_token), message, url, platform)
      end
    end
  end

  private

  def send_notification(tokens, message, url, platform)
    endpoint = ENV.fetch('MOBILE_NOTIFICATION_ENDPOINT')
    msg      = { token: tokens, category: 'invite', platform: platform, message: message, extend: [{ key: 'truthLink', val: url }] }
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

  def request_pool
    RequestPool.current
  end
end

class MarketingPushSubscription < ApplicationRecord
  self.table_name = 'web_push_subscriptions'
  self.primary_key = :device_token
end
