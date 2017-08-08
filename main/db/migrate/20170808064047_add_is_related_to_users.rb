class AddIsRelatedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :wx_related, :boolean, default: false
    add_column :users, :qq_related, :boolean, default: false
    add_column :users, :sina_related, :boolean, default: false
  end
end
