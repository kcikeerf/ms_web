class User < ActiveRecord::Base
  attr_accessor :role_name, :login, :password_confirmation

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable#, :lockable

  belongs_to :role
  has_one :image_upload

  has_many :wx_user_mappings, foreign_key: "user_id"
  has_many :wx_users, through: :wx_user_mappings
  has_many :task_lists, foreign_key: "user_id"

  before_create :set_role#, :check_existed?

  validates :role_name, presence: true, on: :create
  validates :name, presence: true, uniqueness: true, format: { with: /\A([a-zA-Z_]+|(?![^a-zA-Z_]+$)(?!\D+$)).{6,50}\z/ }
  
  validates_confirmation_of :password
  validates :password, length: { in: 6..19 }, presence: true, confirmation: true, if: :password_required?

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
    def generate_rand_password
      result = "" 
      Common::Uzer::PasswdRandLength.times{ result << Common::Uzer::PasswdRandArr.sample }
      result
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
        password = generate_rand_password
        transaction do 
          user = find_by(name: name)
          if user
            #学生只能属于一个班级，若有更新，将更改Location
            user.pupil.update(:loc_uid => options[:loc_uid]) if user.is_pupil? && !options[:loc_uid].blank?
            ClassTeacherMapping.find_or_save_info(user.teacher, options) if user.is_teacher?
            return [user.name, user.initial_password] unless user.initial_password.blank?
            return []
          end
          user = new(name: name, password: password, password_confirmation: password, role_name: role_name, initial_password: password)
          user.save!

          #确定地区

          user.save_after(options.merge({user_id: user.id}))
          return [user.name, password]
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

    def find_user(login, conditions)
      user = 
        case judge_type(login)
        when 'mobile'
          where("phone = ? and phone_validate = ?", login, true)
        when 'email'
          where("lower(email) = ? and email_validate = ?", login.downcase, true)
        else
          where("lower(name) = ?", login.downcase)
        end

      user.where(conditions.to_h).first#.where(["lower(phone) = :value OR lower(email) = :value", { :value => login.downcase }]).first
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
        :email => params[:email] || ""
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
        :email => params[:email] || ""
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

  def accessable_tenants
    result = []
    if self.is_area_administrator?
      result = self.role_obj.area.all_tenants
    elsif self.is_project_administrator?
      result = self.role_obj.tenants
    else
      result = [self.tenant]
    end
    result
  end

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
    result
  end

  def paper_questions
    Mongodb::BankTestUserLink.where(user_id: self.id).map{|item| item.bank_test.paper_question if item.bank_test}.compact
  end

  def bank_tests
    Mongodb::BankTestUserLink.where(user_id: self.id).map{|item| item.bank_test}.compact
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
  ########私有方法: end#######
end
