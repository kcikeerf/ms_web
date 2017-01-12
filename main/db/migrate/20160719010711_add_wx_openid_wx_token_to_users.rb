class AddWxOpenidWxTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :wx_openid, :string, limit: 255
    add_index :users, :wx_openid, unique: true
    add_column :users, :wx_token, :string, limit: 255
  end
end
