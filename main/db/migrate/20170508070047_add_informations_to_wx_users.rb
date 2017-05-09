class AddInformationsToWxUsers < ActiveRecord::Migration
  def change
  	add_column :wx_users, :wx_unionid, :string, limit: 255
  	add_column :wx_users, :nickname, :string, limit: 255
  	add_column :wx_users, :sex, :string, limit: 255
  	add_column :wx_users, :headimgurl, :string, limit: 255
  	add_column :wx_users, :country, :string, limit: 255
  	add_column :wx_users, :province, :string, limit: 255
  	add_column :wx_users, :city, :string, limit: 255
  	add_column :wx_users, :area_uid, :string, limit: 255
  end
end
