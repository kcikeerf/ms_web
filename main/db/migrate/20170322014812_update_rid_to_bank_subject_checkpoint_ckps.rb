class UpdateRidToBankSubjectCheckpointCkps < ActiveRecord::Migration
  def change
  	change_column :bank_subject_checkpoint_ckps, :rid, :string, limit: 255
  end
end
