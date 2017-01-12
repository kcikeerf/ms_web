class CreateJobLists < ActiveRecord::Migration
  def change
    create_table :job_lists,id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :name
      t.string :job_id
      t.string :status
      t.float :process
      t.string :task_uid

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
