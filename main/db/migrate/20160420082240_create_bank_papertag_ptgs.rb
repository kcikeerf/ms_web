class CreateBankPapertagPtgs < ActiveRecord::Migration
  def change
    create_table :bank_papertag_ptgs do |t|

      t.timestamps
    end
  end
end
