class CreateBankCkpCubes < ActiveRecord::Migration
  def change
    create_table :bank_ckp_cubes do |t|

      t.timestamps
    end
  end
end
