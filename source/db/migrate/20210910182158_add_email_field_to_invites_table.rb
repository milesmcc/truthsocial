class AddEmailFieldToInvitesTable < ActiveRecord::Migration[6.1]
  def change
    add_column :invites, :email, :string
  end
end
