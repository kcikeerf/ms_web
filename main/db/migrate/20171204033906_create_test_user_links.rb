class CreateTestUserLinks < ActiveRecord::Migration
  def change
    create_table :test_user_links do |t|
      t.string :user_id
      t.string :bank_test_id
      t.datetime :test_date
      t.integer :test_duration
      t.integer :test_times
      t.string :test_status
      t.string :task_uid

      t.timestamps null: false
    end

    add_index :test_user_links, :user_id
    add_index :test_user_links, :bank_test_id
  end
end
