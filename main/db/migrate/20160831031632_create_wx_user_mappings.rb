class CreateWxUserMappings < ActiveRecord::Migration
  def change
    create_table :wx_user_mappings do |t|

      t.string :user_id
      t.string :wx_uid
      
      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
