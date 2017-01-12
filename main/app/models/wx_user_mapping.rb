class WxUserMapping < ActiveRecord::Base
  
  #concerns
  include TimePatch
  
  belongs_to :user, foreign_key: "user_id"
  belongs_to :wx_user, foreign_key: "wx_uid"
end
