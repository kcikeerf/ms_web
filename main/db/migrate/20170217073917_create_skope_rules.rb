class CreateSkopeRules < ActiveRecord::Migration
  def change
    create_table :skope_rules do |t|
      t.string :name
      t.string :category
      t.integer :priority
      t.string :rkey
      t.string :rvalue
      t.string :desc
      t.string :skope_id

      t.timestamps null: false
    end

    add_index :skope_rules, :category
  end
end
