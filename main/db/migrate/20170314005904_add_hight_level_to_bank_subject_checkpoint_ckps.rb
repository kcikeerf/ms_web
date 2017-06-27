class AddHightLevelToBankSubjectCheckpointCkps < ActiveRecord::Migration
  def change
  	add_column :bank_subject_checkpoint_ckps, :high_level, :boolean, default: false 
  end
end
