class AddTokenToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :tk_token, :string, limit: 255
  end
end
