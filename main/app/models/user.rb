class User < ActiveRecord::Base
  attr_accessor :role_name, :login

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable#, :validatable

  belongs_to :role
  has_one :image_upload

  before_create :set_role#, :check_existed?

  validates :role_name, presence: true, on: :create
  validates :name, presence: true, uniqueness: true, format: { with: /\A([a-zA-Z_]+|(?![^a-zA-Z_]+$)(?!\D+$)).{6,20}\z/ }
  
  validates :password, length: { in: 6..19 }, presence: true, confirmation: true, if: :password_required?

  validates :email, format: { with: /\A[^@\s]+@[^@\s]+\z/ }, allow_blank: true
  validates :phone, format: { with: /\A1\d{10}\z/ }, allow_blank: true

  validate do
#    self.errors.add(:base, '不能为空') if (!email.present? || !phone.present?)
#  	 self.errors.add(:base, '用户已存在') if self.class.find_user(email.presence || phone, {})
    self.errors.add(:email, '已存在') if email.presence && self.class.where.not(id: id).find_by(email: email)
    self.errors.add(:phone, '已存在') if phone.presence && self.class.where.not(id: id).find_by(phone: phone)    
  end

  def self.find_for_database_authentication(warden_conditions)
  	conditions = warden_conditions.dup
  	login = conditions.delete(:login)
    find_user(login, conditions)
  	# where(conditions.to_h).where(["lower(phone) = :value OR lower(email) = :value", { :value => login.downcase }]).first
  end

  #添加用户
  #pupil: User.add_user('xxx', 'pupil', {loc_uid: '1111111', name: 'xx', stu_number: '1234', sex: 'nan'})
  #teacher: User.add_user('xxx', 'teacher', {loc_uid: '1111111', name: 'xx', subject: 'english', head_teacher: true})
  def self.add_user(name, role_name, options={})
    password = ((1..9).to_a + ('a'..'z').to_a - ['o', 'i']).sample(8).join
    transaction do 
      user = find_by(name: name)
      if user
        ClassTeacherMapping.find_or_create_info(user.teacher, options) if user.is_teacher?
        return []
      end
      user = new(name: name, password: password, role_name: role_name)
      return false unless user.save

      user.save_after(options.merge({user_id: user.id}))
      return [user.name, password]
    end
  end

  def save_after(options)
    model = 
      case 
      when is_analyzer? then Analyzer
      when is_pupil? then Pupil
      when is_teacher? then Teacher
      else nil
      end

    model.save_info(options) if model
  end

  def is_pupil?
    role?(Common::Role::Pupil)
  end

  def is_teacher?
    role?(Common::Role::Teacher)
  end

  def is_analyzer?
    role?(Common::Role::Analyzer)
  end

  def role_obj
    return analyzer if is_analyzer?
    return teacher if is_teacher?
    return pupil if is_pupil?
  end

  def pupil
    is_pupil? ? Pupil.where("user_id = ?", self.id).first : nil
  end

  def teacher
    is_teacher? ? Teacher.where("user_id = ?", self.id).first : nil
  end

  def analyzer
    is_analyzer? ? Analyzer.where("user_id = ?", self.id).first : nil
  end

  def role?(r)
    role.name.include? r.to_s
  end

  def self.forgot_password_validate_user(login)
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

  def self.judge_type(user_name)
    case user_name
      when /\A1\d{10}\z/ then 'mobile'
      when /\A[^@\s]+@[^@\s]+\z/ then 'email'
      else 'name'
    end
  end

  #生成忘记密码token
  def save_token
    set_reset_password_token
  end

  private

  def self.find_user(login, conditions)
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

  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
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
end
