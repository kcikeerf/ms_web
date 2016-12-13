# -*- coding: UTF-8 -*-

class Mongodb::BankTest
  include Mongoid::Document
  include Mongodb::MongodbPatch
  
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  belongs_to :bank_paper_pap, class_name: "Mongodb::BankPaperPap"
  has_many :bank_test_tenant_links, class_name: "Mongodb::BankTestTenantLink", dependent: :delete
  has_many :bank_test_task_links, class_name: "Mongodb::BankTestTaskLink", dependent: :delete
  has_many :bank_test_cloud_resource_links, class_name: "Mongodb::BankTestCloudResourceLink"

  scope :by_user, ->(user_id) { where(user_id: user_id) }

  field :name, type: String
  field :quiz_date, type: DateTime
  field :user_id, type: String
  field :report_version, type: String

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({_id: 1}, {background: true})
  
  def tenants
    tenant_uids = bank_test_tenant_links.map(&:tenant_uid)
    Tenant.where(uid: tenant_uids)
  end

  def tenant_list
    bank_test_tenant_links.map{|t|
      job = JobList.where(uid: t.job_uid).first
      {
        :tenant_uid => t.tenant_uid,
        :tenant_name => t.tenant.name_cn,
        :tenant_status => t.tenant_status,
        :job_uid => t.job_uid,
        :job_progress => job.nil?? 0 : (job.process*100).to_i
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

  def update_test_tenants_status tenant_uids, status_str, options={}
    begin
      #测试各Tenant的状态更新
      bank_test_tenant_links.each{|t|
        if tenant_uids.include?(t[:tenant_uid])
          t.update({
            :tenant_status => status_str,
            :job_uid => options[:job_uid]
          }) 
        end
      }
   
      # 试卷的json中，插入测试tenant信息，未来考虑丢掉
      target_pap = self.bank_paper_pap
      paper_h = JSON.parse(target_pap.paper_json)
      paper_h["information"]["tenants"].each_with_index{|item, index|
        if tenant_uids.include?(item["tenant_uid"])
          paper_h["information"]["tenants"][index]["tenant_status"] = status_str
          paper_h["information"]["tenants"][index]["tenant_status_label"] = Common::Locale::i18n("tests.status.#{status_str}")
        end
      }
      target_pap.update(:paper_json => paper_h.to_json)
    rescue Exception => ex

    end
  end
end
