class CreateBankNodestructures < ActiveRecord::Migration
  def change
    create_table :bank_nodestructures, id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :subject, limit: 50
      t.string :version, limit: 50
      t.string :grade, limit: 50
      t.string :volume, limit: 50
      t.string :rid, limit: 128
#      t.string :node, limit: 200
#      t.timestamps
      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
