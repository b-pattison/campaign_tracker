class AddXpModeAndTotalXpAndPlayedAtToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :xp_mode, :string
    add_column :sessions, :total_xp, :integer, null: true
    add_column :sessions, :played_at, :datetime, null: true
  end
end
