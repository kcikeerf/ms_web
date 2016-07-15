class CreatePermissions < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.string :name
      t.string :subject_class
      t.string :action
      t.string :description
      t.integer :role_id
      
      t.timestamps
    end
  end
end
