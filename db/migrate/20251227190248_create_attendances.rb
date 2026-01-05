class CreateAttendances < ActiveRecord::Migration[8.0]
  def change
    create_table :attendances do |t|
      t.references :session, null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true
      t.boolean :present, default: true, null: false
      t.integer :xp_earned, default: 0, null: false

      t.timestamps
    end
  end
end
