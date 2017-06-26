class AddIndexesToV11Tables < ActiveRecord::Migration
  def change
  	add_index :pupils, :user_id
  	add_index :pupils, :loc_uid
  	add_index :pupils, :stu_number
  	add_index :pupils, :tenant_uid
  	add_index :teachers, :user_id
  	add_index :teachers, :loc_uid
  	add_index :teachers, :tenant_uid
  	add_index :wx_users, :wx_openid
  	add_index :wx_user_mappings, :user_id
  	add_index :wx_user_mappings, :wx_uid
  	add_index :locations, :tenant_uid
  	add_index :class_teacher_mappings, :tea_uid
  	add_index :class_teacher_mappings, :loc_uid
  	add_index :class_teacher_mappings, :tenant_uid
  end
end
