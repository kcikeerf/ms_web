class AddWxTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :wx_openid, :string, limit: 255
    add_index :users, :wx_openid, unique: true
  end
end
