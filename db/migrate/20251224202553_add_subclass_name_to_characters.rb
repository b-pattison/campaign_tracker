class AddSubclassNameToCharacters < ActiveRecord::Migration[8.0]
  def change
    add_column :characters, :subclass_name, :string
  end
end
