class Mongodb::BankTest
  include Mongoid::Document
  include Mongodb::MongodbPatch
  
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  field :name, type: String
  field :quiz_date, type: DateTime
  field :user_id, type: String

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  belongs_to :bank_paper_paps, class_name: "Mongodb::BankPaperPap"
  has_many :bank_test_tenant_links, class_name: "Mongodb::BankTestTenantLink", dependent: :delete 

  scope :by_user, ->(user_id) { where(user_id: user_id) }

  def tenants
    tenant_uids = bank_test_tenant_links.map(&:tenant_uid)
    Tenant.where(uid: tenant_uids)
  end
end
