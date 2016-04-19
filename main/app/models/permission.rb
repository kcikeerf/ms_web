class Permission < ActiveRecord::Base
  #has_many :roles, foreign_key: "permission_id", through: :roles_permissions_links 
  has_many :roles_permissions_links
  has_many :roles, :through => :roles_permissions_links 
end
