class CreateUserLocationLinks < ActiveRecord::Migration
  def change
    create_table :user_location_links do |t|
      t.string :user_id
      t.string :loc_uid
      t.timestamps null: false
    end

    add_index :user_location_links, :user_id
    add_index :user_location_links, :loc_uid
  end
end
