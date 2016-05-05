class CreateBankDicQuiztypes < ActiveRecord::Migration
  def change
    create_table :bank_dic_quiztypes ,id:false do |t|
      t.string :sid, limit: 50
      t.string :caption, limit: 200
      t.string :desc, limit: 500
      t.timestamps
    end
  end
end
