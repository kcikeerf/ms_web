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
  has_many :bank_test_task_links, class_name: "Mongodb::BankTestTaskLink", dependent: :delete

  scope :by_user, ->(user_id) { where(user_id: user_id) }

  def tenants
    tenant_uids = bank_test_tenant_links.map(&:tenant_uid)
    Tenant.where(uid: tenant_uids)
  end

  def tenant_list
    bank_test_tenant_links.map{|t|
      {
        :tenant_uid => t.tenant_uid,
        :tenant_name => t.tenant.name_cn,
        :tenant_status => t.tenant_status,
        :job_uid => t.job_uid
      } 
    }
  end

  def tasks
    task_uids = bank_test_task_links.map(&:task_uid)
    TaskList.where(uid: task_uids)
  end

  def task_list
    bank_test_task_links.map{|t|
      {
        :task_uid => t.task_uid,
        :task_name => t.task.name,
        :task_status => t.task.status,
        :task_type => t.task.task_type
      }
    }
  end

  def score_uploads
    ScoreUpload.where(test_id: id.to_s)
  end
end
