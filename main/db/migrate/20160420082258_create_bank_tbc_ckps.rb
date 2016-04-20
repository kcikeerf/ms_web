class CreateBankTbcCkps < ActiveRecord::Migration
  def change
    create_table :bank_tbc_ckps do |t|

      t.timestamps
    end
  end
end
