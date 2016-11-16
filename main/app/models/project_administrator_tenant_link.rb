class ProjectAdministratorTenantLink < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid
  
  belongs_to :project_administrator, foreign_key: "project_administrator_uid"
  belongs_to :tenant, foreign_key: "tenant_uid"
end
