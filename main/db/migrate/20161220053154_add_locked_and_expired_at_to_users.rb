class AddLockedAndExpiredAtToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :locked, :boolean, :default => true
  	add_column :users, :expired_at, :datetime, :default => nil

  	User.update_all(:locked => false)
  end
end
