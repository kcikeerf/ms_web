class ScoreUpload < ActiveRecord::Base
  mount_uploader :filled_file, ScoreUploader
  mount_uploader :empty_file, EmptyScoreUploader
  mount_uploader :usr_pwd_file, UserPasswordUploader
  mount_uploader :user_base, UserBaseUploader

  #belongs_to :analyzer, foreign_key: "ana_uid"
  scope :by_tenant_uid, ->(uid) { where(tenant_uid: uid).order({updated_at: :desc}) }

end
