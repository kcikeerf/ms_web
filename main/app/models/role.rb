class Role < ActiveRecord::Base
  has_many :users, foreign_key: "role_id"
  #has_many :permissions, foreign_key: "role_id", through: :roles_permissions_links
  has_many :roles_permissions_links
  has_many :permissions, :through => :roles_permissions_links
  accepts_nested_attributes_for :permissions
end
