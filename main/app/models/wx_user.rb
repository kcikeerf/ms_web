class WxUser < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  belongs_to :area, foreign_key: "area_uid"
  has_many :wx_user_mappings, foreign_key: "wx_uid", dependent: :destroy
  has_many :users, through: :wx_user_mappings

  before_save :set_area

  def binded_user? user_name
     names = users.map{|u| u.name}
     names.include? user_name
  end

  def binded_users_list
    guest_user!
    users.map{|u|
      {
        :id => u.id,
        :user_name => u.name,
        :name => u.role_obj.nil?? "-":u.role_obj.name,
        :role => u.role.name
      }
    }
  end

  def online_tests
    links = Mongodb::OnlineTestUserLink.by_wx_user(self.id)
    online_test_ids = links.map(&:online_test_id)
    Mongodb::OnlineTest.where(id: online_test_ids).to_a
  end

  # 是否已绑定用户
  def binded?
    !users.blank?
  end

  # Guest用户
  def guest_user
    users.find{|u| u.is_guest? }
  end

  # 无Guest用户，则创建Guest用户
  def guest_user!
    return guest_user if self.guest_user

    option_h = {
      :name => Common::Uzer::WxUserNamePrefix + self.wx_openid,
      :password => self.wx_openid,
      :role_name => Common::Role::Guest
    }
    target_user = User.new(option_h)
    return nil unless target_user.save!
    self.users << target_user
  end

  ########私有方法: begin#######
  private
    def set_area
      option_h = {}
      target_area = Area.where(name_cn: self.city) if !self.city.blank?
      target_area = Area.where(name_cn: self.province) if target_area.blank? && !self.province.blank?
      self.area_uid = target_area.uid if target_area
    end
end
