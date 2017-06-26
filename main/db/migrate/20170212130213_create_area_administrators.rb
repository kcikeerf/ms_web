class CreateAreaAdministrators < ActiveRecord::Migration
  def change
    create_table :area_administrators, id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :user_id
      t.string :name
      t.string :desc
      t.string :area_uid
      t.string :area_rid

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
