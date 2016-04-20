class CreateBankPapertagPtgs < ActiveRecord::Migration
  def change
    create_table :bank_papertag_ptgs,id:false do |t|
      t.string :sid, limit: 200
#      t.timestamps
      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
