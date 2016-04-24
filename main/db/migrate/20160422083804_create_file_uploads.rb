class CreateFileUploads < ActiveRecord::Migration
  def change
    create_table :file_uploads do |t|
      t.string :paper
      t.string :answer
      t.string :analysis

      t.timestamps
    end
  end
end
