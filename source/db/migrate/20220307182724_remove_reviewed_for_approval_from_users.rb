class RemoveReviewedForApprovalFromUsers < ActiveRecord::Migration[6.1]
  def change
    safety_assured { remove_column :users, :reviewed_for_approval, :boolean }
  end
end
