class CreateReportUrlMappings < ActiveRecord::Migration
  def change
    create_table :report_url_mappings, id:false do |t|
      t.column :codes, "VARCHAR(255) PRIMARY KEY"
      t.string :params_json
      t.boolean :first_login, default: true
      t.datetime :dt_add
      t.datetime :dt_update
    end
  end
end
