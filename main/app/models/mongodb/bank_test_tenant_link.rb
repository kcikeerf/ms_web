# -*- coding: UTF-8 -*-
#

class Mongodb::BankTestTenantLink
  include Mongoid::Document
  include Mongodb::MongodbPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  belongs_to :bank_test, class_name: "Mongodb::BankTest"

  #field :test_id, type: String
  field :tenant_uid, type: String
  field :tenant_status, type: String
  #等之后设计了Task Job Panel此字段可弃用
  field :job_uid, type: String

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({bank_test_id: 1, tenant_uid: 1}, {unique: true, background: true})
  
  def tenant
    Tenant.where(uid: tenant_uid).first
  end
end
