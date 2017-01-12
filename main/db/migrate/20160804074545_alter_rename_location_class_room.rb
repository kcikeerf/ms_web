class AlterRenameLocationClassRoom < ActiveRecord::Migration
  def change
    rename_column :locations, :class_room, :classroom
  end
end
