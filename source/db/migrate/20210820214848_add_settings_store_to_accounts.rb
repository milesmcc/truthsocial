class AddSettingsStoreToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :settings_store, :jsonb, default: {}
  end
end
