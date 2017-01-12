class AddCategoryToBankSubjectCheckpointCkps < ActiveRecord::Migration
  def change
  	add_column :bank_subject_checkpoint_ckps, :category, :string, limit: 255
  end
end
