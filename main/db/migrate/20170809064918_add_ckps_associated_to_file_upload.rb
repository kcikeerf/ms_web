class AddCkpsAssociatedToFileUpload < ActiveRecord::Migration
  def change
    add_column :file_uploads, :ckps_associated, :string
  end
end
