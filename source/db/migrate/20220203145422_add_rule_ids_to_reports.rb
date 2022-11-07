class AddRuleIdsToReports < ActiveRecord::Migration[6.1]
  def change
    add_column :reports, :rule_ids, :integer, array: true, null: false, default: []
  end
end
