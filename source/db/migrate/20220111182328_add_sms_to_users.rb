class AddSmsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :sms, :string
  end
end
