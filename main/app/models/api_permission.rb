class ApiPermission < ActiveRecord::Base
  has_many :roles_api_permissions_links, dependent: :destroy
  has_many :roles, :through => :roles_api_permissions_links , foreign_key: "api_permission_id"
end
