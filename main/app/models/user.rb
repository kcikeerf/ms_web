class User < ActiveRecord::Base
  attr_accessor :role_name, :login, :password_confirmation

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable, # :lockable
    password_length: 6..128

  belongs_to :role
  has_one :image_upload

  has_many :wx_user_mappings, foreign_key: "user_id", dependent: :destroy
  has_many :wx_users, through: :wx_user_mappings
  has_many :task_lists, foreign_key: "user_id"
  has_many :oauth_access_tokens, foreign_key: "resource_owner_id", class_name: "Doorkeeper::AccessToken"#, dependent: :destroy
  has_many :oauth_access_grants, foreign_key: "resource_owner_id", class_name: "Doorkeeper::AccessGrant"#, dependent: :destroy
  has_many :oauth_applications, foreign_key: "resource_owner_id", class_name: "Doorkeeper::Application"#, dependent: :destroy
  has_many :groups_as_parent, :foreign_key=>"child_id", :class_name=>'UserLink'
  has_many :groups_as_child, :foreign_key => "parent_id", :class_name=>"UserLink"
  has_many :parents, :through=>:groups_as_parent
  has_many :children, :through=>:groups_as_child
  scope :by_master, ->(val) { where(is_master: val) }

  before_create :set_role,:generate_token #, :check_existed?
  before_destroy :set_resource_owner_id

  validates :role_name, presence: true, on: :create
  validates :name, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z]{1,1}[a-zA-Z0-9_-]{5,127}\z/ }
  
  validates_confirmation_of :password
  validates :password, length: { in: 6..128 }, presence: true, confirmation: true, if: :password_required?

  validates :email, format: { with: /\A[^@\s]+@[^@\s]+\z/ }, allow_blank: true
  validates :phone, format: { with: /\A1\d{10}\z/ }, allow_blank: true

  validate do
#    self.errors.add(:base, '不能为空') if (!email.present? || !phone.present?)
#  	 self.errors.add(:base, '用户已存在') if self.class.find_user(email.presence || phone, {})
    self.errors.add(:email, '已存在') if email.presence && self.class.where.not(id: id).find_by(email: email)
    self.errors.add(:phone, '已存在') if phone.presence && self.class.where.not(id: id).find_by(phone: phone)    
  end

  ########类方法定义：begin#######
  class << self
    def generate_rand_password len=6
      Common::Uzer::PasswdRandArr[1..-1].sample + (len -1).times.map{ Common::Uzer::PasswdRandArr.sample }.join("")
    end

    def find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      login = conditions.delete(:login)
      find_user(login, conditions)
      # where(conditions.to_h).where(["lower(phone) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    end

    #上传成绩时，添加用户处理
    #pupil: User.add_user('xxx', 'pupil', {loc_uid: '1111111', name: 'xx', stu_number: '1234', sex: 'nan'})
    #teacher: User.add_user('xxx', 'teacher', {loc_uid: '1111111', name: 'xx', subject: 'english', head_teacher: true})
    def add_user(name, role_name, options={})
      begin
        password = generate_rand_password(Common::Uzer::PasswdRandLength)
        transaction do 
          user = find_by(name: name)
          if user
            #学生只能属于一个班级，若有更新，将更改Location
            user.pupil.update(:loc_uid => options[:loc_uid]) if user.is_pupil? && !options[:loc_uid].blank?
            ClassTeacherMapping.find_or_save_info(user.teacher, options) if user.is_teacher?
            return [user.name, user.initial_password], true  unless user.initial_password.blank?
            return [],true
          end
          user = new(name: name, password: password, password_confirmation: password, role_name: role_name, initial_password: password)
          user.save!
          #确定地区

          user.save_after(options.merge({user_id: user.id}))
          return [user.name, password],false
        end
      rescue Exception => ex
        logger.debug ex.message
        logger.debug ex.backtrace
        return false
      end
    end

    def forgot_password_validate_user(login)
      user = 
        case judge_type(login)
        when 'mobile'
          where("phone = ? and phone_validate = ?", login, true).first
        when 'email'
          where("lower(email) = ? and email_validate = ?", login.downcase, true).first
        end
      unless user
        user = new
        user.errors.add(:login, '您输入的手机号码／邮箱不存在，请重新输入') 
      end
      user
    end

    def judge_type(user_name)
      case user_name
        when /\A1\d{10}\z/ then 'mobile'
        when /\A[^@\s]+@[^@\s]+\z/ then 'email'
        else 'name'
      end
    end

    def find_user(login, conditions={})
      user = 
        case judge_type(login)
        when 'mobile'
          where("phone = ? and phone_validate = ?", login, true)
        when 'email'
          where("lower(email) = ? and email_validate = ?", login.downcase, true)
        else
          where("lower(name) = ?", login.downcase)
        end
      user = user.where(conditions.to_h).where(is_master: true).first#.where(["lower(phone) = :value OR lower(email) = :value", { :value => login.downcase }]).first
      result = nil
      if user
        if user.parents.size < 1
          result = user
        end
      end
      return result
    end

    # 给doorkeeper验证用户
    def authenticate(login, option_h)
      user = find_user(login)
      # 通常密码认证
      if !option_h[:password].blank?
        user.try(:valid_password?, option_h[:password]) ? user : nil
      # 微信openid认证
      elsif !option_h[:wx_openid].blank?
        wx_openids = user.wx_users.map(&:wx_openid)
        wx_openids.include?(option_h[:wx_openid]) ? user : nil
      # 微信的unionid认证
      elsif !option_h[:wx_unionid].blank?
        wx_unionids = user.wx_users.map(&:wx_unionid)
        wx_unionids.include?(option_h[:wx_unionid]) ? user : nil   
      else
        nil
      end
    end    
  end
  ########类方法定义：end#######

  def save_user(role_name, params)
    #transaction do 
      paramsh = {
        :name => params[:user_name], 
        :password => params[:password], 
        :password_confirmation => params[:password_confirmation],
        :role_name => role_name,
        :qq => params[:qq] || "",
        :phone => params[:phone] || "",
        :email => params[:email] || "",
        :is_master => params[:is_master] || false,
      }
      return self unless update_attributes(paramsh)

      save_role_obj(params.merge({user_id: self.id}))
      return self
    #end
  end

  def update_user(role_name, params)
   #transaction do       
      paramsh = {
        :name => params[:user_name], 
        :role_name => role_name,
        :qq => params[:qq] || "",
        :phone => params[:phone] || "",
        :email => params[:email] || "",
        :is_master => params[:is_master] || false,
      }
      unless params[:password].blank?
        paramsh[:password] = params[:password]
        paramsh[:password_confirmation] = params[:password_confirmation]
        paramsh[:initial_password] = ""
      end
      return self unless update_attributes(paramsh)

      save_role_obj(params.merge({user_id: self.id}))
      return self
    #end
  end

  #删除关联角色对象用户的实例
  def destroy
    super
    role_obj.destroy if role_obj
  end

  def save_role_obj params
    begin
    role_obj = 
      case 
      when is_analyzer? then (analyzer.nil?? Analyzer.new : analyzer)
      when is_pupil? then (pupil.nil?? Pupil.new : pupil)
      when is_teacher? then (teacher.nil?? Teacher.new : teacher)
      when is_tenant_administrator? then (tenant_administrator.nil?? TenantAdministrator.new : tenant_administrator)
      when is_project_administrator? then (project_administrator.nil?? ProjectAdministrator.new : project_administrator)
      when is_area_administrator? then (area_administrator.nil?? AreaAdministrator.new : area_administrator)
      else nil
      end

    role_obj.save_obj(params) if role_obj
    rescue Exception => ex
      logger.debug ex.messages
      logger.debug ex.backtrace
    end
  end

  def save_after(options)
    model = 
      case 
      when is_analyzer? then Analyzer
      when is_pupil? then Pupil
      when is_teacher? then Teacher
      when is_tenant_administrator? then TenantAdministrator
      when is_project_administrator? then ProjectAdministrator
      when is_area_administrator? then AreaAdministrator  
      else nil
      end

    model.save_info(options) if model
  end

  def self.update_user(name, role_name, options)

  end

  # 生成 是否为角色方法、角色方法
  Common::Role::NAME_ARR.each do |name|
    define_method("is_#{name}?") do 
      role?(name)
    end

    define_method(name) do
     role?(name) ? name.camelcase.constantize.find_by(user_id: id) : nil
    end
  end

  Common::Uzer::ThirdPartyList.each do |oauth2|
    define_method("#{oauth2}_related?") do
      self.send("#{oauth2}_related")
    end
  end

  def role_obj
    return analyzer if is_analyzer?
    return teacher if is_teacher?
    return pupil if is_pupil?
    return tenant_administrator if is_tenant_administrator?
    return project_administrator if is_project_administrator?
    return area_administrator if is_area_administrator?
  end  

  def role?(r)
    role.name.include? r.to_s if role && role.name
  end

  #生成忘记密码token
  def save_token
    set_reset_password_token
  end

  def tenant
    result = nil
    if is_pupil?
      result = role_obj.location.tenant if role_obj && role_obj.location
    else
      result = role_obj.tenant if role_obj
    end
    result
  end

  # 可访问Tenant
  def accessable_tenants
    result = []
    if self.is_area_administrator?
      result = self.role_obj.area.all_tenants
    elsif self.is_project_administrator?
      result = self.role_obj.tenants
    else
      result = [self.tenant]
    end
    result.sort{|a,b| a.name <=> b.name }
  end

  # 可访问班级（分组）
  def accessable_locations
    result = []
    target_tenants = self.accessable_tenants
    
    # 老师在当前所属租户担当教学的班级
    if self.is_teacher?
      result = self.role_obj.locations({:tenant_uid => target_tenants.map(&:uid)})
    # 学生在当前所属租户的所属班级
    elsif self.is_pupil?
      result = [self.role_obj.location]
    # 其它返回空记录
    else
      result = target_tenants.map{|item| item.locations}.flatten
    end
    result.compact!
    result.uniq!
    result.sort{|a,b| b.dt_update <=> a.dt_update}
  end

  # 可访问测试
  def accessable_tests
    result = []
    if self.is_area_administrator?
      result = self.role_obj.area.bank_tests
    elsif self.is_tenant_administrator?
      result = self.accessable_tenants.map{|t| t.bank_tests}.flatten     
    elsif self.is_teacher?
      result = self.accessable_locations.map{|l| l.bank_tests}.flatten
    elsif self.is_pupil?
      result = self.bank_tests
    else
      result = []
    end
    result.compact!
    result.uniq!
    result.sort{|a,b| b.dt_update <=> a.dt_update}
  end

  # 用户当前所属分组
  def report_top_group_kv is_public=true
    if is_public
      rpt_type = Common::Report2::Group::Pupil
      rpt_id = self.tk_token
    else
      rpt_type = nil
      rpt_id = nil
      if self.is_area_administrator? || self.is_project_administrator?
        #
      elsif self.is_tenant_administrator? || self.is_teacher?
        rpt_type = Common::Report::Group::Grade
        rpt_id = self.accessable_tenants.blank?? nil : self.accessable_tenants.first.uid
      elsif self.is_pupil?
        rpt_type = Common::Report::Group::Pupil
        rpt_id = self.role_obj.uid
      else
        #
      end
    end
    return rpt_type,rpt_id
  end

  def bank_tests
    Mongodb::BankTestUserLink.by_user(self.id).map{|item| item.bank_test}.compact
  end

  #当前用户绑定的用户列表
  def binded_users_list
    user_list  = {}
    user_list[:master] = self.get_user_base_info
    user_list[:slave] = children.map {|u|
      u.get_user_base_info
    }
    return user_list
  end

  def fresh_access_token
    target_token = Doorkeeper::AccessToken.find_or_create_for(
      nil, #client
      self.id, #resource_owner_id
      "", #scopes
      7200, #expired in
      true # use refresh token?
    )
    {
      :access_token => target_token.token,
      :token_type => "bear",
      :expires_in => target_token.expires_in,
      :refresh_token => target_token.refresh_token,
      :scope => "",
      :created_at => target_token.created_at.to_i
    } 
  end

  def get_user_base_info  
    oauth_hash = fresh_access_token 
    user_base_info = {
      :id => self.id,
      :user_name => self.name,
      :name => self.role_obj.nil? ? "-" : self.role_obj.name,
      :role => self.role.nil? ? "默认" : self.role.name,       
    }
    third_hash = {}
    if self.is_master
      user_base_info[:is_customer] = self.is_customer
      t_name = nil
      Common::Uzer::ThirdPartyList.each do |oauth2|
        if send("#{oauth2}_related?")
          oauth2_users = send("#{oauth2}_users")
          oauth2_user = oauth2_users.first
          if oauth2_user
            oauth2_obj = {
              nickname: oauth2_user.nickname,
              sex: oauth2_user.sex,
              headimgurl: oauth2_user.headimgurl
            }
            third_hash[oauth2] = oauth2_obj
          end
          user_base_info["#{oauth2}_related"] = true
          t_name ||=  oauth2_user.nickname
        else
          user_base_info["#{oauth2}_related"] = false
        end
      end
      nick_base = t_name.present? ? t_name : self.name
      user_base_info[:name] = self.nickname.present? ? self.nickname : nick_base
    end
    if third_hash.present?
      user_base_info[:third_party] = third_hash
    end
    user_base_info[:oauth] = oauth_hash
    user_base_info
  end

  #从主账号中解绑子账号
  def users_unbind user_name
    flag = false
    unbind_user = User.where(name: user_name).first
    if unbind_user
      if unbind_user == self
        code = "e41005"
      else
        if self.children.include?(unbind_user)
          self.children.delete(unbind_user)
          code = "i11001"
          flag = true
        else
          code = "w21002"
        end
      end
    else
      code = "e40004"
    end
    return flag,code
  end

  def slave_user _user
    status = 500
    if (self.children.count + 1) > Common::Uzer::UserBindingMaxLimit
      code = "w21000"
    elsif (_user.parents.count + 1) > Common::Uzer::UserBoundMaxLimit
      code = "w21001"
    else
      if self.children.include?(_user)
        code,status = "i11002", 200
      else
        if self.children.push(_user)
          code,status = "i11000", 200
        else
          code = "e41003"
        end
      end
    end
    return code, status
  end

  def associate_master target_3rd_user, target_user, oauth2
    master_user = target_3rd_user.users.by_master(true).first
    unless  master_user 
      target_3rd_user.users << target_user unless target_3rd_user.users.include?(target_user)
      code, status = "i11215",200
    else
      if master_user == target_user
        code, status = "i11215",200
      else
        if ((target_user.children.map(&:id) + master_user.children.map(&:id)).uniq.size) > Common::Uzer::UserBindingMaxLimit
          code, status = "w21005",500
        else
          target_user.children += master_user.children
          target_3rd_user.users.delete(master_user)
          option_h = {"#{oauth2}_related" => true}
          target_user.update(option_h)
          target_3rd_user.users << target_user unless target_3rd_user.users.include?(target_user)
          code, status = "i11215",200
        end
      end
    end
    return code, status
  end

  # 是否已绑定微信
  def wx_binded?
    !wx_users.blank?
  end

  ########私有方法: begin#######
  private

    def password_required?
      !persisted? || !password.nil? || !password_confirmation.nil?
    end

    # Email is not required
    def email_required?
      false
    end

    def set_role
      self.role_id = Role.get_role_id(role_name)
    end

    def check_existed?
      if self.class.find_user(email.presence || phone, {})
        self.errors.add(:base, I18.t("activerecord.errors.messages.exited_user"))
        raise SwtkErrors::UserExistedError.new(I18.t("activerecord.errors.messages.exited_user"))
      end
    end

    def generate_token
      self.tk_token = loop do
        random_token = SecureRandom.urlsafe_base64(nil, false)
        break random_token unless self.class.exists?(tk_token: random_token)
      end
    end

    def set_resource_owner_id
      oauth_access_tokens.update_all(resource_owner_id: nil)
      oauth_access_grants.update_all(resource_owner_id: nil)
      oauth_applications.update_all(resource_owner_id: nil)
    end
  ########私有方法: end#######
end
