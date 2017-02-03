class RolesPermissionsLink < ActiveRecord::Base
  belongs_to :role, foreign_key: "role_id"
  belongs_to :permission, foreign_key: "permission_id"
end
