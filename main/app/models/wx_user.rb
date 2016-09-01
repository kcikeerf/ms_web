class WxUser < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  has_many :wx_user_mappings, foreign_key: "wx_uid", dependent: :destroy
  has_many :users, through: :wx_user_mappings

  def binded_user? user_name
     names = users.map{|u| u.name}
     names.include? user_name
  end

  def binded_users_list
    users.map{|u|
      {
        :id => u.id,
        :user_name => u.name,
        :name => u.role_obj.nil?? "-":u.role_obj.name
      }
    }
  end
end