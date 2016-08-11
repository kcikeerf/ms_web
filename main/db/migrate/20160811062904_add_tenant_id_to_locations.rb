class AddTenantIdToLocations < ActiveRecord::Migration
  def change
    add_column :locations, :tenant_id, :string, limit: 255 
  end
end
