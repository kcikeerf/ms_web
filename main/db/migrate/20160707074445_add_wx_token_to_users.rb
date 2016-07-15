class AddWxTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :wx_token, :string, limit: 255
    add_index :users, :wx_token, unique: true
  end
end
