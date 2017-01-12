class AddWxUserIdToTaskLists < ActiveRecord::Migration
  def change
  	add_column :task_lists, :wx_user_id, :string, limit: 255 
  end
end
