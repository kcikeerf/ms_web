class CreateUserTenantLinks < ActiveRecord::Migration
  def change
    create_table :user_tenant_links do |t|
      t.string :user_id
      t.string :tenant_uid
      t.timestamps null: false
    end

    add_index :user_tenant_links, :user_id
    add_index :user_tenant_links, :tenant_uid
  end
end
