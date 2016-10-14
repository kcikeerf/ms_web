class ProjectAdministrator < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  belongs_to :user
  has_many :tenants, through: :project_administrator_tenant_links
  has_many :project_administrator_tenant_links, foreign_key: "project_administrator_uid"
end
