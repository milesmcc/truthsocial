class CreateCsvExports < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    create_table :csv_exports do |t|
      t.string :model, null: false
      t.string :app_id, null: false
      t.string :file_url, null: false
      t.string :status, default: 'PROCESSING'
      t.references :user, null: false

      t.timestamps
    end
  end
end
