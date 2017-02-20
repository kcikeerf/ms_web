class UserSkopeLink < ActiveRecord::Base
  belongs_to :user, foreign_key: "user_id"
  belongs_to :skope, foreign_key: "skope_id"
end
