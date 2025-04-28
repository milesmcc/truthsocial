class ChangeListAccountFollowNullable < ActiveRecord::Migration[5.1]
  def change
    safety_assured do
      change_column_null :list_accounts, :follow_id, true
    end
  end
end
