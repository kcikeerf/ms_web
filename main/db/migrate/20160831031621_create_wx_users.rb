class CreateWxUsers < ActiveRecord::Migration
  def change
    create_table :wx_users,id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :name
      t.string :wx_openid, :unique => true
      t.string :wx_token
      t.string :comment

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
