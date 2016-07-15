class CreateClassTeacherMappings < ActiveRecord::Migration
  def change
    create_table :class_teacher_mappings,id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :tea_uid
      t.string :loc_uid
      t.string :subject
      t.boolean :head_teacher, default: false

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
