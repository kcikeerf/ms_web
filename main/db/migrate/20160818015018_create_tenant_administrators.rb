class CreateTenantAdministrators < ActiveRecord::Migration
  def change
    create_table :tenant_administrators, id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY", limit: 50
      t.integer :user_id, null: false
      t.string :name
      t.string :tenant_uid
      t.string :comment

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
