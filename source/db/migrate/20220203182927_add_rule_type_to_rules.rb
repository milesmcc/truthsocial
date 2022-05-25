class AddRuleTypeToRules < ActiveRecord::Migration[6.1]
  def change
    add_column :rules, :rule_type, :integer, default: 0
    add_column :rules, :subtext, :text, null: false, default: ""
  end
end
