class AddAreaUidAuthenticationTokenToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :area_uid, :string
  	add_column :users, :authentication_token, :string

    add_index :users, :area_uid
    add_index :users, :authentication_token
  end
end
