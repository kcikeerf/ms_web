class CreateProjectAdministratorTenantLinks < ActiveRecord::Migration
  def change
    create_table :project_administrator_tenant_links,id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :project_administrator_uid
      t.string :tenant_uid

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
