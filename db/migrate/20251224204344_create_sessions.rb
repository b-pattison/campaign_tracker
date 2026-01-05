class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions do |t|
      t.references :campaign, null: false, foreign_key: true
      t.datetime :scheduled_at, null: false
      t.text :recap
      t.string :location
      t.string :status, null: false

      t.timestamps
    end
  end
end
