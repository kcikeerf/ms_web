class CreateCheckpointSystems < ActiveRecord::Migration
  def change
    create_table :checkpoint_systems, id: false do |t|
      t.column :rid, "VARCHAR(255) PRIMARY KEY", limit: 50
      t.string :name
      t.boolean :is_group
      t.string :sys_type
      t.string :version
      t.text :desc, limit: 2000

      t.timestamps null: false
    end
  end
end
