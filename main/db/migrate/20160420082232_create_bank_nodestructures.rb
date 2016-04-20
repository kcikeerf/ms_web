class CreateBankNodestructures < ActiveRecord::Migration
  def change
    create_table :bank_nodestructures do |t|

      t.timestamps
    end
  end
end
