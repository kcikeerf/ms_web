class CreateSwtkConfigs < ActiveRecord::Migration
  def change
    create_table :swtk_configs, id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :name,:unique => true
      t.string :value
      t.string :desc

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
