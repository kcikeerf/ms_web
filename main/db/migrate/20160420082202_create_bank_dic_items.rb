class CreateBankDicItems < ActiveRecord::Migration
  def change
    create_table :bank_dic_items do |t|

      t.timestamps
    end
  end
end
