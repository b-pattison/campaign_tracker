class CreateCharacters < ActiveRecord::Migration[8.0]
  def change
    create_table :characters do |t|
      t.references :campaign, null: false, foreign_key: true
      t.string :name
      t.string :class_name
      t.integer :level
      t.string :ancestry
      t.text :notes

      t.timestamps
    end
  end
end
