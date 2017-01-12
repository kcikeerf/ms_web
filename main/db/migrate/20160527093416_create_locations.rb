class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations,id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :province
      t.string :city
      t.string :district
      t.string :school
      t.string :school_label
      t.string :school_number
      t.string :grade
      t.string :class_room

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
