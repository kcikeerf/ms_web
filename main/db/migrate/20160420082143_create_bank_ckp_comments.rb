class CreateBankCkpComments < ActiveRecord::Migration
  def change
    create_table :bank_ckp_comments do |t|

      t.timestamps
    end
  end
end
