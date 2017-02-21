class AddNameLabelToRoles < ActiveRecord::Migration
  def change
  	add_column :roles, :name_label, :string	
  end
end
