class RemoveRoleIdActionAndAddOperationToPermissions < ActiveRecord::Migration
  def change
  	remove_column :permissions, :role_id, :string
  	remove_column :permissions, :action, :string
  	add_column :permissions, :operation, :string
  end
end
