class AddTransactionalEmailOptOutBooleanToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :unsubscribe_from_emails, :boolean, default: false
  end
end
