class RolesApiPermissionsLink < ActiveRecord::Base
  belongs_to :role, foreign_key: "role_id"
  belongs_to :api_permission, foreign_key: "api_permission_id"
end
