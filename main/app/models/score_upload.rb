class ScoreUpload < ActiveRecord::Base
  mount_uploader :filled_file, ScoreUploader
  mount_uploader :empty_file, EmptyScoreUploader
  mount_uploader :usr_pwd_file, UserPasswordUploader

  #belongs_to :analyzer, foreign_key: "ana_uid"
end
