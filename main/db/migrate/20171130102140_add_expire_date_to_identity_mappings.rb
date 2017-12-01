class AddExpireDateToIdentityMappings < ActiveRecord::Migration
  def change
    add_column :identity_mappings, :expire_date, :date
  end
end
