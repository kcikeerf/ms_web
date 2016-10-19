class Mongodb::BankTestTenantLink
  include Mongoid::Document
  include Mongodb::MongodbPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  belongs_to :bank_test, class_name: "Mongodb::BankTest"

  #field :test_id, type: String
  field :tenant_uid, type: String
  field :tenant_status, type: String
  field :job_id, type: String

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  def tenant
    Tenant.where(uid: tenant_uid).first
  end
end
