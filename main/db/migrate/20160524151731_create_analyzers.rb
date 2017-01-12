class CreateAnalyzers < ActiveRecord::Migration
  def change
    create_table :analyzers,id: false do |t|
      t.column :uid, "VARCHAR(255) PRIMARY KEY"
      t.string :user_id
      t.string :name
      t.string :subject

      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
