require Rails.root.join('lib', 'mastodon', 'migration_helpers')

class AddWholeWordToCustomFilter < ActiveRecord::Migration[5.2]
  include Mastodon::MigrationHelpers

  disable_ddl_transaction!

  def change
    safety_assured do
      add_column_with_default :custom_filters, :whole_word, :boolean, default: true, allow_null: false
    end
  end

  def down
    remove_column :custom_filters, :whole_word
  end
end
