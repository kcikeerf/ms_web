class CreateCheckpointSystems < ActiveRecord::Migration
  def change
    create_table :checkpoint_systems do |t|
      t.string :name
      t.string :rid
      t.boolean :is_group
      t.string :sys_type
      t.string :version
      t.text :desc, limit: 2000

      t.timestamps null: false
    end
  end
end
