class CreateBankCkpCats < ActiveRecord::Migration
  def change
    create_table :bank_ckp_cats, id:false do |t|
      t.column :nid, 'INTEGER PRIMARY KEY AUTO_INCREMENT'
      t.string :cat_uid, limit: 36
      t.string :ckp_uid, limit: 36
      t.datetime :dt_add
      t.datetime :dt_update

      t.timestamps
    end
  end
end
