class UserTenantLink < ActiveRecord::Base
  belongs_to :user, foreign_key: "user_id"
  belongs_to :tenant, foreign_key: "tenant_uid"
end
