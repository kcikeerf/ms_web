class CreateBankDics < ActiveRecord::Migration
  def change
    create_table :bank_dics, id: false do |t|
      t.string :sid, limit: 50
      t.string :caption, limit: 200
      t.text :desc, limit: 500
#      t.timestamps
      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
