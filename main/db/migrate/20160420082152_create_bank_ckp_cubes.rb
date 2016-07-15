class CreateBankCkpCubes < ActiveRecord::Migration
  def change
    create_table :bank_ckp_cubes, id: false do |t|
      t.column :nid, 'INTEGER PRIMARY KEY AUTO_INCREMENT'
      t.string :ckp_uid_k, limit: 36
      t.string :ckp_uid_s, limit: 36
      t.string :ckp_uid_a, limit: 36
      t.integer :crosstype
#      t.timestamps
      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
