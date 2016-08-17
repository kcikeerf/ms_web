class AddTenantId < ActiveRecord::Migration
  def change
    add_column :analyzers, :tenant_uid, :string, limit: 255 
    add_column :teachers, :tenant_uid, :string, limit: 255 
    add_column :pupils, :tenant_uid, :string, limit: 255 
    add_column :locations, :tenant_uid, :string, limit: 255
    add_column :class_teacher_mappings, :tenant_uid, :string, limit: 255
  end
end
