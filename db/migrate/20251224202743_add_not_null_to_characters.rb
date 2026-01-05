class AddNotNullToCharacters < ActiveRecord::Migration[7.1]
  def change
    change_column_null :characters, :name, false
    change_column_null :characters, :class_name, false
    change_column_null :characters, :level, false
    change_column_null :characters, :campaign_id, false
  end
end

