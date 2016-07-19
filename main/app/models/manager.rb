class Manager < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :trackable, :validatable

  def self.left_menus
    [
      {
        id: 1, icon: 'icon-sys', name: '指标体系',
        menus: [
          {id: 12, name: '教材管理', icon: '', url: '/managers/node_structures'},
          {id: 13, name: '指标体系管理', icon: '', url: '/managers/checkpoints'},
          {id: 14, name: '科目指标体系管理', icon: '', url: '/managers/subject_checkpoints'}
        ]
      },
      {
        id: 2, icon: 'icon-sys', name: '用户管理',
        menus: [
          {id: 21, name: '角色管理', icon: '', url: '/managers/roles'},
          {id: 22, name: '权限管理', icon: '', url: '/managers/permissions'}
        ]
      }
    ]
  end
end
