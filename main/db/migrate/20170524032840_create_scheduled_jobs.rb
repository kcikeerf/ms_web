class CreateScheduledJobs < ActiveRecord::Migration
  def change
    create_table :scheduled_jobs, id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :name
      t.string :cron
      t.string :klass
      t.string :queue
      t.text :args
      t.boolean :active_job
      t.string :queue_name_prefix
      t.string :queue_name_delimiter
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps null: false
    end
  end
end
