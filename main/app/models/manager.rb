class Manager < ActiveRecord::Base

  attr_accessor :login

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :trackable, :validatable

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    find_user(login, conditions)
  end

  def self.left_menus
    [
      {
        id: 1, icon: 'icon-sys', name: '用户管理',
        menus: [
          {id: 11, name: '角色管理', icon: '', url: '/managers/roles'},
          {id: 12, name: '权限管理', icon: '', url: '/managers/permissions'},
          {id: 13, name: 'Tenant管理', icon: '', url: '/managers/tenants'},
        ]
      },
      {
        id: 2, icon: 'icon-sys', name: '指标体系',
        menus: [
          {id: 21, name: '教材管理', icon: '', url: '/managers/node_structures'},
          {id: 22, name: '指标体系管理', icon: '', url: '/managers/checkpoints'},
          {id: 23, name: '科目指标体系管理', icon: '', url: '/managers/subject_checkpoints'}
        ]
      }
    ]
  end

  private

  def self.find_user(login, conditions)
    user = 
      case judge_type(login)
      when 'mobile'
        where("phone = ? and phone_validate = ?", login, true)
      when 'email'
        where("lower(email) = ?", login.downcase)
      else
        where("lower(name) = ?", login.downcase)
      end

    user.where(conditions.to_h).first#.where(["lower(phone) = :value OR lower(email) = :value", { :value => login.downcase }]).first
  end

  def self.judge_type(user_name)
    case user_name
      when /\A1\d{10}\z/ then 'mobile'
      when /\A[^@\s]+@[^@\s]+\z/ then 'email'
      else 'name'
    end
  end
end
