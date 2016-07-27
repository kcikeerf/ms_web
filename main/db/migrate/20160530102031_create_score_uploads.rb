class CreateScoreUploads < ActiveRecord::Migration
  def change
    create_table :score_uploads do |t|
      t.string :filled_file
      t.string :empty_file
      t.string :ana_uid
      t.string :usr_pwd_file

      t.timestamps
    end
  end
end
