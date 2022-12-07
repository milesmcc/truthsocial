class AddIndexToDeviceToken < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :web_push_subscriptions, :device_token, algorithm: :concurrently
  end
end
