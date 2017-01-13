class AddIndexesToV11Tables < ActiveRecord::Migration
  def change
  	add_index :pupils, :user_id
  	add_index :pupils, :loc_uid
  	add_index :pupils, :stu_number
  	add_index :pupils, :tenant_uid
  	add_index :teachers, :user_id
  	add_index :teachers, :loc_uid
  	add_index :tachers, :tenant_uid
  	add_index :wx_users, :wx_openid
  	add_index :locations, :tenant_uid
  	add_index :class_teacher_mapping, :tea_uid
  	add_index :class_teacher_mapping, :loc_uid
  	add_index :class_teacher_mapping, :tenant_uid
  end
end
