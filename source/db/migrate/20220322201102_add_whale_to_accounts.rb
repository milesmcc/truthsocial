class AddWhaleToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :whale, :boolean,  default: false
  end
end
