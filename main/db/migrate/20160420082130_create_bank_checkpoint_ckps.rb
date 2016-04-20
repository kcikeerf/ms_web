class CreateBankCheckpointCkps < ActiveRecord::Migration
  def change
    create_table :bank_checkpoint_ckps do |t|

      t.timestamps
    end
  end
end
