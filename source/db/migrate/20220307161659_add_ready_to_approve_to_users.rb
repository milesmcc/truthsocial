class AddReadyToApproveToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :ready_to_approve, :integer, default: 0
  end
end
