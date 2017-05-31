class AlterHighLevelDefaultValueToBankSubjectCheckpointCkps < ActiveRecord::Migration
  def change
  	change_column_default :bank_subject_checkpoint_ckps, :high_level, nil
  end
end
