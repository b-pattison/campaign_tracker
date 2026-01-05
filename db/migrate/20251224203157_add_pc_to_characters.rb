class AddPcToCharacters < ActiveRecord::Migration[8.0]
  def change
    add_column :characters, :pc, :boolean, default: true, null: false
  end
end
