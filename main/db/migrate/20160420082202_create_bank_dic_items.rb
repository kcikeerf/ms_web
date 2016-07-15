class CreateBankDicItems < ActiveRecord::Migration
  def change
    create_table :bank_dic_items, id: false do |t|
      t.column :sid, "VARCHAR(50) PRIMARY KEY"
      t.string :dic_sid, limit: 50
      t.string :caption, limit: 200
      t.text :desc, limit: 500
#      t.timestamps
      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
