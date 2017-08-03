class AddColumnToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_master, :boolean, default: false
    add_column :users, :is_customer, :boolean, default: false
    add_column :users, :id_card, :string
    add_index :users, :id_card
    add_index :users, :is_master
    add_index :users, :is_customer
  end
end
