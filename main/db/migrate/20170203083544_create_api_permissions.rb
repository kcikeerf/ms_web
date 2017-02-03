class CreateApiPermissions < ActiveRecord::Migration
  def change
    create_table :api_permissions do |t|
      t.string :name
      t.string :method
      t.string :path      
      t.string :description

      t.timestamps null: false
    end
  end
end
