class AddDeletedAtToBankSubjectCheckpointCkp < ActiveRecord::Migration
  def change
    add_column :bank_subject_checkpoint_ckps, :deleted_at, :datetime
    add_index :bank_subject_checkpoint_ckps, :deleted_at
  end
end
