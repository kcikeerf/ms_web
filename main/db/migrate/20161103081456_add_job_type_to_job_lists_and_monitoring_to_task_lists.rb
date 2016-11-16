class AddJobTypeToJobListsAndMonitoringToTaskLists < ActiveRecord::Migration
  def change
  	add_column :job_lists, :job_type, :string
  	add_column :task_lists, :monitoring, :boolean
  end
end
