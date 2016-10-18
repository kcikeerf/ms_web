class CreateMongodbBankTestTenantLinks < ActiveRecord::Migration
  def change
    create_table :mongodb_bank_test_tenant_links,id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :bank_test_id
      t.string :tenant_uid

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
