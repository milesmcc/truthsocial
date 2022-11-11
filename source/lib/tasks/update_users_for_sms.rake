# frozen_string_literal: true

namespace :update_users_for_sms do
  desc 'sends alerts to a group of pending users without sms to verify their sms'
  task prompt_for_sms: :environment do
    batch_size = ENV.fetch('SMS_BATCH_SIZE', 50_000).to_i

    abort('Please make your batch_size less than 50,000.') if batch_size > 50_000

    users = User.includes(:account)
                .pending
                .where(ready_to_approve: 2)
                .where(sms: nil)
                .joins("INNER JOIN web_push_subscriptions ON web_push_subscriptions.user_id = users.id")
                .distinct
                .limit(batch_size)

    users.find_each do |user|
      NotifyService.new.call(user.account, :verify_sms_prompt, user)
      user.update_columns(ready_to_approve: 3)
    end
  end
end