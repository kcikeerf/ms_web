class CreateTeachers < ActiveRecord::Migration
  def change
    create_table :teachers,id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :user_id
      t.string :loc_uid
      t.string :name
      t.string :subject
      t.string :school

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
