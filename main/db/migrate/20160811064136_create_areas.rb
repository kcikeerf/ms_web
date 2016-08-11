class CreateAreas < ActiveRecord::Migration
  def change
    create_table :areas,id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :rid
      t.string :area_type
      t.string :name
      t.string :name_cn
      t.string :comment

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
