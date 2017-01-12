class CreateBankDicQuiztypes < ActiveRecord::Migration
  def change
    create_table :bank_dic_quiztypes ,id:false do |t|
      t.column :sid, "VARCHAR(50) PRIMARY KEY"
      t.string :caption, limit: 200
      t.string :desc, limit: 500
      t.timestamps
    end
  end
end
