class AddMobileParamsToWebPushSubscriptions < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_column :web_push_subscriptions, :device_token, :string, default: nil
      add_column :web_push_subscriptions, :platform, :integer, default: 0
      add_column :web_push_subscriptions, :environment, :integer, default: 0

      change_column_null :web_push_subscriptions, :endpoint, true
      change_column_null :web_push_subscriptions, :key_p256dh, true
      change_column_null :web_push_subscriptions, :key_auth, true
    end
  end
end
