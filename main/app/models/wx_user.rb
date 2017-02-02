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
      target_token = AuthWl::Token.get_token_obj u.id
      {
        #:id => u.id,
        :user_name => u.name,
        :name => u.role_obj.nil?? "-":u.role_obj.name,
        :role => u.role.name,
        :auth => { 
          token_type: "Bearer",
          access_token: target_token.access_token,
          expires_in: target_token.expired_at.strftime("%s").to_i - Time.now.strftime("%s").to_i,
          refresh_token: target_token.refresh_token
        }
      }
    }
  end

  def online_tests
    links = Mongodb::OnlineTestUserLink.by_wx_user(self.id)
    online_test_ids = links.map(&:online_test_id)
    Mongodb::OnlineTest.where(id: online_test_ids).to_a
  end
end
