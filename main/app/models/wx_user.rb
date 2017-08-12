class WxUser < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  belongs_to :area, foreign_key: "area_uid"
  has_many :wx_user_mappings, foreign_key: "wx_uid", dependent: :destroy
  has_many :users, through: :wx_user_mappings

  before_save :set_area, :set_sex

  def binded_user? user_name
     names = users.map{|u| u.name}
     names.include? user_name
  end

  def binded_users_list
    default_user!
    users.map{|u|
      target_token = Doorkeeper::AccessToken.find_or_create_for(
          nil, #client
          u.id, #resource_owner_id
          "", #scopes
          7200, #expired in
          true # use refresh token?
      )
      {
        :id => u.id,
        :user_name => u.name,
        :name => u.role_obj.blank? ? "-":u.role_obj.name,
        :role => u.role.blank? ? "-":u.role.name,
        :oauth => {
          :access_token => target_token.token,
          :token_type => "bear",
          :expires_in => target_token.expires_in,
          :refresh_token => target_token.refresh_token,
          :scope => "",
          :created_at => target_token.created_at.to_i
        }
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
  def default_user
    users.find{|u| u.is_guest? }
  end

  # 无Guest用户，则创建Guest用户
  def default_user!
    return default_user if self.default_user
    # if self.nickname
    #   user_name = Common::Uzer::WxUserNamePrefix + self.nickname
    #   target_user = User.where(name: user_name).first
    #   if target_user
    #     user_name = Common::Uzer::WxUserNamePrefix + self.wx_openid  if self.wx_openid
    #     user_name = Common::Uzer::WxUserNamePrefix + self.wx_unionid  if self.wx_unionid
    #   end
    # else
    #   user_name = Common::Uzer::WxUserNamePrefix + self.wx_openid  if self.wx_openid
    #   user_name = Common::Uzer::WxUserNamePrefix + self.wx_unionid  if self.wx_unionid      
    # end
    user_name = Common::Uzer::WxUserNamePrefix + self.wx_openid  if self.wx_openid
    user_name = Common::Uzer::WxUserNamePrefix + self.wx_unionid  if self.wx_unionid
    option_h = {
      :name => user_name,
      :password => self.wx_unionid.present? ? self.wx_unionid  : self.wx_openid,
      :role_name => Common::Role::Guest,
      :is_customer => true,
      :is_master => true,
      :wx_related => true
    }
    target_user = User.where(name: option_h[:name]).first
    unless target_user
      target_user = User.new(option_h)
      target_user.save!
    end
    self.save!
    self.users << target_user
  end

  def master
    users.by_master(true).first 
  end

  # 必须执行过swtk_patch::v1_2::update_wx_user_is_master
  #
  def migrate_other_wx_user_binded_user _other_wx_user
    master_user = nil
    master_user = self.master if self.users
    unless master_user
      self.default_user!
      master_user = self.master if self.users
    end

    _other_master_user = _other_wx_user.master
    _target_users = _other_master_user.present? ? _other_master_user.children : _other_wx_user.users

    master_user.children += _target_users
    # _other_master_user.destroy if _other_master_user
  end

  ########私有方法: begin#######
  private
    def set_area
      option_h = {}
      target_area = Area.where(name_cn: self.city).first if !self.city.blank?
      target_area = Area.where(name_cn: self.province).first if target_area.blank? && !self.province.blank?
      self.area_uid = target_area.uid if target_area
    end

    def set_sex
      self.sex = case self.sex 
      when "0" 
        "wu" 
      when "1"
        "nan" 
      when "2"
        "nv"
      else
        self.sex
      end
    end
end
