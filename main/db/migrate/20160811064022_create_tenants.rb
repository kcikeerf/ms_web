class CreateTenants < ActiveRecord::Migration
  def change
    create_table :tenants,id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :number
      t.string :name
      t.string :name_en
      t.string :name_cn
      t.string :name_abbrev
      t.string :moto
      t.string :k12_type
      t.string :school_type
      t.string :address
      t.string :email
      t.string :phone
      t.string :web
      t.string :build_at
      t.string :comment

      t.string :area_uid

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
