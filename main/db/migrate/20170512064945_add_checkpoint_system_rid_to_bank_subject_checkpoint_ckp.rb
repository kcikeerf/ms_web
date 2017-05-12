class AddCheckpointSystemRidToBankSubjectCheckpointCkp < ActiveRecord::Migration
  def change
	  add_column :bank_subject_checkpoint_ckps, :checkpoint_system_rid, :string, index: true, foreign_key: true
  end
end
