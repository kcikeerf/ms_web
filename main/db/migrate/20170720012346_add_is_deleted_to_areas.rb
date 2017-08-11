class AddIsDeletedToAreas < ActiveRecord::Migration
  def change
    add_column :areas, :is_deleted, :boolean, default: false
  end
end
