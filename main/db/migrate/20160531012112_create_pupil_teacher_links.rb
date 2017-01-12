class CreatePupilTeacherLinks < ActiveRecord::Migration
  def change
    create_table :pupil_teacher_links,id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :tea_uid
      t.string :pup_uid

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
