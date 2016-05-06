class User < ActiveRecord::Base

	attr_accessor :role_name, :login

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  belongs_to :role

  before_create :set_role

  validates :role_name, presence: true

  # validate do 
  # 	self.add_to_base('用户已存在') if find_user(email.presence || phone)
  # end

  def self.find_for_database_authentication(warden_conditions)
  	conditions = warden_conditions.dup
  	login = conditions.delete(:login)
  	where(conditions.to_h).where(["lower(phone) = :value OR lower(email) = :value", { :value => login.downcase }]).first
  end


  def role?(r)
    role.name.include? r.to_s
  end

  private

  def find_user(login, conditions)
  	where(conditions.to_h).where(["lower(phone) = :value OR lower(email) = :value", { :value => login.downcase }]).first
  end

  def set_role
  	self.role_id = Role.get_role_id(role_name)
  end

end
