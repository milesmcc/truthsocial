class CreateTrendings < ActiveRecord::Migration[6.1]
  def change
    create_table :trendings do |t|
      t.references :status, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
