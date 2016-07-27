class AddSortToCheckpointCkps < ActiveRecord::Migration
  def change
  	add_column :bank_checkpoint_ckps, :sort, :string, limit: 255#, default: 0
  	add_column :bank_subject_checkpoint_ckps, :sort, :string, limit: 255#, default: 0
  end
end
