class AddDeletedByToStatuses < ActiveRecord::Migration[6.1]
  def change
    safety_assured {
      add_column :statuses, :deleted_by_id, :bigint, null: true, default: nil
    }
  end
end
