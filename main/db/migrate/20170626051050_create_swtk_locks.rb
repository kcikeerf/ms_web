class CreateSwtkLocks < ActiveRecord::Migration
  def change
    create_table :swtk_locks, id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.integer :locked_mode, default: nil
      t.integer :locked_times, default: 1
      t.string :locked_owner
      t.string :resource_type
      t.string :resource_id
      t.string :job_uid

      t.timestamps null: false
    end
  end
end
