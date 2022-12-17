class CreateModerationRecords < ActiveRecord::Migration[6.1]
  def change
    create_table :moderation_records do |t|
      t.references :status
      t.references :media_attachment

      t.jsonb :analysis

      t.timestamps
    end
  end
end
