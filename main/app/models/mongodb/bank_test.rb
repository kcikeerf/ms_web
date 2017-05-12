# -*- coding: UTF-8 -*-

class Mongodb::BankTest
  include Mongoid::Document
  include Mongodb::MongodbPatch
  
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp, :generate_ext_data_path

  belongs_to :bank_paper_pap, class_name: "Mongodb::BankPaperPap"
  belongs_to :paper_question, class_name: "Mongodb::PaperQuestion"

  has_many :bank_test_task_links, class_name: "Mongodb::BankTestTaskLink", dependent: :delete
  has_many :bank_test_area_links, class_name: "Mongodb::BankTestAreaLink", dependent: :delete
  has_many :bank_test_tenant_links, class_name: "Mongodb::BankTestTenantLink", dependent: :delete
  has_many :bank_test_location_links, class_name: "Mongodb::BankTestLocationLink", dependent: :delete
  has_many :bank_test_user_links, class_name: "Mongodb::BankTestUserLink", dependent: :delete

  scope :by_user, ->(id) { where(user_id: id) }
  scope :by_type, ->(str) { where(quiz_type: str) }

  field :name, type: String
  field :quiz_type, type: String
  field :quiz_date, type: DateTime
  field :user_id, type: String
  field :report_version, type: String
  field :ext_data_path, type: String
  field :report_top_group, type: String
  field :checkpoint_system_rid, type: String
  field :is_public, type: Boolean

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({_id: 1}, {background: true})
  index({bank_paper_pap_id: 1}, {background: true})

  def area_uids
    bank_test_area_links.map(&:area_uid)
  end

  def areas
    Area.where(uid: area_uids)
  end

  def tenant_uids
    bank_test_tenant_links.map(&:tenant_uid)
  end

  def tenants
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

  def loc_uids
    bank_test_location_links.map(&:loc_uid)
  end

  def locations
    Location.where(uid: loc_uids)
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
      unless paper_h["information"]["tenants"].blank?
        paper_h["information"]["tenants"].each_with_index{|item, index|
          if tenant_uids.include?(item["tenant_uid"])
            paper_h["information"]["tenants"][index]["tenant_status"] = status_str
            paper_h["information"]["tenants"][index]["tenant_status_label"] = Common::Locale::i18n("tests.status.#{status_str}")
          end
        }
        target_pap.update(:paper_json => paper_h.to_json)
      end 
    rescue Exception => ex
      logger.debug ex.message
      logger.debug ex.backtrace
    end
  end

  def checkpoint_system
    CheckpointSytem.where(id: self.checkpoint_system_id).first
  end

  ###私有方法###
  private

    # 随机生成6位外挂码，默认生成码以"___"（三个下划线）开头
    # 
    def generate_ext_data_path
      unless self.ext_data_path
        self.ext_data_path = Common::Test::ExtDataPathDefaultPrefix
        Common::Test::ExtDataPathLength.times{ self.ext_data_path << Common::Test::ExtDataCodeArr.sample}
      end
    end
end
