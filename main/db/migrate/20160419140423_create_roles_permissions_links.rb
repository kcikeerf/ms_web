class CreateRolesPermissionsLinks < ActiveRecord::Migration
  def change
    create_table :roles_permissions_links do |t|
      t.integer :role_id
      t.integer :permission_id
      t.timestamps
    end
  end
end
