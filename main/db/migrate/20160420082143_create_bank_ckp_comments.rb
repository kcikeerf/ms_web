class CreateBankCkpComments < ActiveRecord::Migration
  def change
    create_table :bank_ckp_comments, id: false do |t|
      t.string :uid, limit: 36
      t.string :ckp_uid, limit: 36
      t.string :ban_uid, limit: 36
      t.string :target, limit: 36
      t.text :template, limit: 1000
#      t.timestamps
      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
