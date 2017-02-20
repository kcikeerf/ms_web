class UserLocationLink < ActiveRecord::Base
  belongs_to :user, foreign_key: "user_id"
  belongs_to :location, foreign_key: "loc_uid"
end
