class CreateSkopes < ActiveRecord::Migration
  def change
    create_table :skopes do |t|
      t.string :name
      t.string :desc

      t.timestamps null: false
    end
  end
end
