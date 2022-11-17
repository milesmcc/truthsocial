# frozen_string_literal: true

namespace :push_notifications do
  desc 'sends ad hoc alerts to inactive users'
  task send_to_inactive: :environment do
    to_hour   = ENV.fetch('TO_HOUR', 48).to_i
    from_hour = ENV.fetch('FROM_HOUR', 0).to_i
    test_mode = ENV.fetch('TEST', 0).to_i
    message   = ENV.fetch('MESSAGE')
    url       = ENV.fetch('URL')

    abort('MESSAGE and URL are required.') if message.blank? || url.blank?

    users = User.approved.joins('inner join web_push_subscriptions on users.id = web_push_subscriptions.user_id')

    if test_mode.positive?
      test_accounts = %w[bj northwall MattheusWagner jolynn]
      users = users.joins(:account).where(accounts: {username: test_accounts})
    else
      users = users.where("current_sign_in_at <= ?", Time.current.midnight - to_hour.hours)
      users = users.where("current_sign_in_at >= ?", Time.current.midnight - from_hour.hours) if from_hour.positive?
    end

    start_at = Time.current

    user_ids = users.pluck(:id)
    ::Mobile::MarketingNotificationWorker.queue_notifications(user_ids: user_ids, message: message, url: url)
    duration = Time.current - start_at
    puts "Queued #{user_ids.length} in #{duration.round} seconds (#{(user_ids.length / duration).round(1)} per second)"
  end
end