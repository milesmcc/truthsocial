# frozen_string_literal: true

class Mobile::ChannelNotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'push', retry: 5

  TTL     = 8.hours.to_s
  URGENCY = 'normal'

  def self.queue_notifications(message:)
    users = User
      .select(:id, :account_id)
      .approved
      .joins('inner join accounts on users.account_id = accounts.id')
      .where(accounts: { accepting_messages: true })
      .where(
        Web::PushSubscription.where('web_push_subscriptions.user_id = users.id and web_push_subscriptions.platform = 1')
        .arel.exists
      )
      .where.not(
        Block.where('blocks.account_id = accounts.id and blocks.target_account_id = ?', message.created_by_account_id)
        .arel.exists
      )
      .where(
        ChatMember.where('chat_members.chat_id = ? and chat_members.account_id = accounts.id and active = true', message.chat_id)
        .arel.exists
      )

    url = ActivityPub::TagManager.instance.url_for_chat_message(message.message_id)

    users.in_batches(of: 2_000) do |batch|
      self.perform_async(batch.pluck(:id), message.content, url)
    end
  end

  def perform(user_ids, content, url)
    tokens   = Web::PushSubscription.where(user_id: user_ids, platform: 1).where.not(device_token: nil).pluck(:device_token)
    endpoint = ENV.fetch('MOBILE_NOTIFICATION_ENDPOINT')
    msg      = {token: tokens, category: 'invite', platform: 1, message: content, extend: [{key: 'truthLink', val: url}]}
    body     = { 'notifications' => [msg] }.to_json
    
    return unless endpoint.present? && tokens.any? && content && url

    request_pool.with(Addressable::URI.parse(endpoint).normalized_site) do |http_client|
      request = Request.new(:post, endpoint, body: body, http_client: http_client)
      request.add_headers('Content-Type' => 'application/octet-stream')
      request.perform do |response|
        raise Mastodon::UnexpectedResponseError, response if !(200...300).cover?(response.code)
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
