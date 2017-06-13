class AddColumnToScoreUploads < ActiveRecord::Migration
  def change
    add_column :score_uploads, :user_base, :string
    add_column :file_uploads, :user_base, :string
  end
end
