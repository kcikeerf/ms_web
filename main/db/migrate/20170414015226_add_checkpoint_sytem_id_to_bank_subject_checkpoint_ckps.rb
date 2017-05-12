class AddCheckpointSytemIdToBankSubjectCheckpointCkps < ActiveRecord::Migration
  def change
  	add_column :bank_subject_checkpoint_ckps, :checkpoint_system_id, :integer
  end
end
	