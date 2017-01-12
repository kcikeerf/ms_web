class CreatePupils < ActiveRecord::Migration
  def change
    create_table :pupils, id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY", limit: 50
      t.integer :user_id, null: false
      t.string :loc_uid
      t.string :stu_number
      t.string :name
      t.string :sex, limit: 10
      t.string :grade
      t.string :classroom
      t.string :school

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end	
end
