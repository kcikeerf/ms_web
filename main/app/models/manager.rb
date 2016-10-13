class Manager < ActiveRecord::Base

  attr_accessor :login

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :trackable, :validatable

  validates :name, presence: true, uniqueness: true, format: { with: /\A([a-zA-Z_]+|(?![^a-zA-Z_]+$)(?!\D+$)).{6,20}\z/ }
  
  validates :password, length: { in: 6..19 }, presence: true, confirmation: true, if: :password_required?

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
          {id: 11, name: I18n.t("managers.menus.jue_se_guan_li"), icon: '', url: '/managers/roles'},
          {id: 12, name: I18n.t("managers.menus.quan_xian_guan_li"), icon: '', url: '/managers/permissions'},
          {id: 13, name: I18n.t("managers.menus.project_admin_guan_li"), icon: '', url: '/managers/tenants'},
          {id: 14, name: I18n.t("managers.menus.tenant_guan_li"), icon: '', url: '/managers/tenants'},
          {id: 15, name: I18n.t("managers.menus.tenant_yong_hu_guan_li"), icon: '', url: '/managers/tenant_administrators'},
          {id: 16, name: I18n.t("managers.menus.fen_xi_yuan_guan_li"), icon: '', url: '/managers/analyzers'},
          {id: 17, name: I18n.t("managers.menus.jiao_shi_guan_li"), icon: '', url: '/managers/teachers'},
          {id: 18, name: I18n.t("managers.menus.xue_sheng_guan_li"), icon: '', url: '/managers/pupils'}
        ]
      },
      {
        id: 2, icon: 'icon-sys', name: '指标体系',
        menus: [
          # {id: 21, name: I18n.t("managers.menus.jiao_cai_guan_li"), icon: '', url: '/managers/node_structures'},
          # {id: 22, name: I18n.t("managers.menus.zhi_biao_ti_xi_guan_li"), icon: '', url: '/managers/checkpoints'},
          {id: 23, name: I18n.t("managers.menus.ke_mu_zhi_biao_ti_xi_guan_li"), icon: '', url: '/managers/subject_checkpoints'}
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
