class AddCheckpointSytemIdToBankSubjectCheckpointCkps < ActiveRecord::Migration
  def change
  	add_column :bank_subject_checkpoint_ckps, :checkpoint_sytem_id, :string, limit: 255
  end
end
