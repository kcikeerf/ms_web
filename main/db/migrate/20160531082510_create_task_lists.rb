class CreateTaskLists < ActiveRecord::Migration
  def change
    create_table :task_lists ,id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :name
      t.string :task_type
      t.string :ana_uid
      t.string :pap_uid
      t.string :status

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
