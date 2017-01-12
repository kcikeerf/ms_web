class AddSectionToBankNodeCatalogs < ActiveRecord::Migration
  def change
  	add_column :bank_node_catalogs, :rid, :string, limit: 255 
  end
end
