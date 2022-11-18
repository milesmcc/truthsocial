class AddUnauthVisibilityToUsers < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!
  def change
    add_column :users, :unauth_visibility, :boolean
  end
end