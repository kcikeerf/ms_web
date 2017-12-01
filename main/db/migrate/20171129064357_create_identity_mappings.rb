class CreateIdentityMappings < ActiveRecord::Migration
  def change
    create_table :identity_mappings do |t|
      t.integer :user_id
      t.string :code
      t.string :test_id

      t.timestamps null: false
    end
  end
end
