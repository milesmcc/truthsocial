class AddIndexToStatus < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!
  def change
    # add_index :statuses, :conversation_id, algorithm: :concurrently
  end
end