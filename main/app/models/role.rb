class Role < ActiveRecord::Base
  has_many :users, foreign_key: "role_id"
  #has_many :permissions, foreign_key: "role_id", through: :roles_permissions_links
  has_many :roles_permissions_links, dependent: :destroy
  has_many :permissions, :through => :roles_permissions_links, foreign_key: "role_id"

  has_many :roles_api_permissions_links, dependent: :destroy
  has_many :api_permissions, :through => :roles_api_permissions_links, foreign_key: "role_id"

  accepts_nested_attributes_for :permissions

  validates :name, presence: true


  def self.get_role_id(name)
  	find_by(name: name).try(:id) || 0
  end



end
