class CreateBankDics < ActiveRecord::Migration
  def change
    create_table :bank_dics do |t|

      t.timestamps
    end
  end
end
