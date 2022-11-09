class AddWaitlistPositionToUsers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_column :users, :waitlist_position, :integer
    add_index :users, :waitlist_position, algorithm: :concurrently
  end
end
