class CreateBankNodeCatalogs < ActiveRecord::Migration
  def change
    create_table :bank_node_catalogs, id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :node, limit: 200
      t.string :node_uid, limit: 36
#      t.timestamps
      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
