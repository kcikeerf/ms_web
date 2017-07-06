class CreateUserLinks < ActiveRecord::Migration
  def change
    create_table :user_links, id: false do |t|
      t.integer :parent_id
      t.integer :child_id
    end
  end
end
