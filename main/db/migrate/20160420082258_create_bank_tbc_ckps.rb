
class CreateBankTbcCkps < ActiveRecord::Migration
  def change
    create_table :bank_tbc_ckps, id:false do |t|
      t.column :nid, 'INTEGER PRIMARY KEY AUTO_INCREMENT'
      t.string :tbs_uid, limit: 36
      t.string :ckp_uid3, limit: 36
#      t.timestamps
      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
