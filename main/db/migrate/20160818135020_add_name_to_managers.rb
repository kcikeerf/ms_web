class AddNameToManagers < ActiveRecord::Migration
  def change
  	add_column :managers, :name, :string, limit: 255
  end
end
