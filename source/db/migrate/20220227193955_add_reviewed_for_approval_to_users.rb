class AddReviewedForApprovalToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :reviewed_for_approval, :boolean
  end
end
