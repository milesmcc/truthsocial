require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class AddLocationAndWebsiteToAccount < ActiveRecord::Migration[6.1]

  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def up
    safety_assured { add_column_with_default :accounts, :location, :text, default: '' }
    safety_assured { add_column_with_default :accounts, :website, :text, default: '' }
  end

  def down
    remove_column :accounts, :location
    remove_column :accounts, :website
  end
end
