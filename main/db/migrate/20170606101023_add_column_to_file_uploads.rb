class AddColumnToFileUploads < ActiveRecord::Migration
  def change
    add_column :file_uploads, :paper_structure, :string
    add_column :file_uploads, :combine_checkpoint, :string
    add_column :file_uploads, :xlsx_structure, :string
    add_column :file_uploads, :json_structure, :string
  end
end
