class CreateLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :logs do |t|
      t.string :event, null: false
      t.text :message, null: false, default: ''
      t.string :app_id, null: false

      t.timestamps
    end
    add_index :logs, [:event, :app_id]
  end
end
