class AddIndexToSmsOnUsersTable < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :users, :sms, algorithm: :concurrently
  end
end