class CreateImageUploads < ActiveRecord::Migration
  def change
    create_table :image_uploads do |t|
      t.string :file
      t.string :user_id

      t.timestamps
    end
  end
end
