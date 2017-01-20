class AddAccessTokenToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :token, :string, limit: 255
  	add_column :users, :token_expired_at, :datetime
  end
end
