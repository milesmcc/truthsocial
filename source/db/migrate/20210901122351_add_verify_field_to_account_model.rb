require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class AddVerifyFieldToAccountModel < ActiveRecord::Migration[6.1]

  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def up
    safety_assured { add_column_with_default :accounts, :verified, :bool, default: false }
  end

  def down
    remove_column :accounts, :verified
  end
end
