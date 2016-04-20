class CreateBankCheckpointCkps < ActiveRecord::Migration
  def change
    create_table :bank_checkpoint_ckps, id:false do |t|
      t.string :uid, limit: 36
      t.string :dimesion, limit: 50
      t.string :rid, limit:36
      t.string :checkpoint, limit:200
      t.integer :is_entity
      t.text :desc, limit: 500
#      t.timestamps
      t.datetime :dt_add
      t.datetime :dt_updated
    end
  end
end
