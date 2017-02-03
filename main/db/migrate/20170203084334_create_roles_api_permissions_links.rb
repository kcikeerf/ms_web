class CreateRolesApiPermissionsLinks < ActiveRecord::Migration
  def change
    create_table :roles_api_permissions_links do |t|
      t.integer :role_id
      t.integer :api_permission_id
      t.timestamps null: false
    end
  end
end
