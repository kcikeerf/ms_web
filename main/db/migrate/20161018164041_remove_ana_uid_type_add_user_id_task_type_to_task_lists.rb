class RemoveAnaUidTypeAddUserIdTaskTypeToTaskLists < ActiveRecord::Migration
  def change
  	remove_column :task_lists, :ana_uid, :string
  	#remove_column :task_lists, :type, :string
  	add_column :task_lists, :user_id, :string
  	#add_column :task_lists, :task_type, :string
  end
end
