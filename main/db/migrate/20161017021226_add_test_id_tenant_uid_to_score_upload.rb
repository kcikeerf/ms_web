class AddTestIdTenantUidToScoreUpload < ActiveRecord::Migration
  def change
	add_column :score_uploads, :test_id, :string, limit: 255 
    add_column :score_uploads, :tenant_uid, :string, limit: 255 
  end
end
