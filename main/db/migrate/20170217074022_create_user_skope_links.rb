class CreateUserSkopeLinks < ActiveRecord::Migration
  def change
    create_table :user_skope_links do |t|
      t.string :user_id
      t.string :skope_id

      t.timestamps null: false
    end

    add_index :user_skope_links, :user_id
    add_index :user_skope_links, :skope_id
  end
end
