# -*- coding: UTF-8 -*-

class Mongodb::BankTest
  include Mongoid::Document
  include Mongodb::MongodbPatch
  include SwtkLockPatch

  before_destroy :clear_old_test_state
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp, :generate_ext_data_path

  belongs_to :bank_paper_pap, class_name: "Mongodb::BankPaperPap"
  belongs_to :paper_question, class_name: "Mongodb::PaperQuestion"
  belongs_to :union_test, class_name: "Mongodb::UnionTest"

  has_many :bank_test_task_links, class_name: "Mongodb::BankTestTaskLink", dependent: :delete
  has_many :bank_test_area_links, class_name: "Mongodb::BankTestAreaLink", dependent: :delete
  has_many :bank_test_tenant_links, class_name: "Mongodb::BankTestTenantLink", dependent: :delete
  has_many :bank_test_location_links, class_name: "Mongodb::BankTestLocationLink", dependent: :delete
  has_many :bank_test_user_links, class_name: "Mongodb::BankTestUserLink", dependent: :delete

  has_one :bank_test_state, class_name: "Mongodb::BankTestState"
  has_many :bank_test_group_state, class_name: "Mongodb::BankTestGroupState"

  scope :by_user, ->(id) { where(user_id: id) }
  scope :by_type, ->(str) { where(quiz_type: str) }
  scope :by_public, ->(flag) { where(is_public: flag) }
  scope :by_name, ->(name) { where(name: /#{name}/) if name.present?}

  field :name, type: String
  field :quiz_type, type: String  #测试类型：期中／期末
  field :start_date, type: DateTime
  field :quiz_date, type: DateTime #默认为截止日期
  field :user_id, type: String
  field :report_version, type: String
  field :ext_data_path, type: String
  field :report_top_group, type: String
  field :checkpoint_system_rid, type: String
  field :is_public, type: Boolean
  field :area_rid, type: String
  field :test_status, type: String
  field :test_type, type: String #测试类型：在线／离线


  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({_id: 1}, {background: true})
  index({bank_paper_pap_id: 1}, {background: true})

  class << self
    def get_list params
      params[:page] = params[:page].blank?? Common::SwtkConstants::DefaultPage : params[:page]
      params[:rows] = params[:rows].blank?? Common::SwtkConstants::DefaultRows : params[:rows]
      conditions = {}
      %w{ name quiz_type}.each{|attr|
         conditions[attr] = Regexp.new(params[attr]) unless params[attr].blank? 
       }
      date_range = {}
      date_range[:start_date] = {'$gte' => params[:start_date]} unless params[:start_date].blank? 
      date_range[:quiz_date] = {'$lt' => params[:quiz_date]} unless params[:quiz_date].blank? 
    
      result = self.where(conditions).where(date_range).order("dt_update desc").page(params[:page]).per(params[:rows])
      test_result = []

      result.each_with_index{|item, index|
        h  = item.add_value_to_item
        test_result[index] = h
      }
      return test_result, self.count
    end

  end

  #获取用户绑定情况
  def get_user_binded_stat
    #获取学生报告的路径
    _report_warehouse_path = Common::Report::WareHouse::ReportLocation + "reports_warehouse/tests/"
    target_pupil_urls = Dir[_report_warehouse_path + self._id + "/**/pupil/*.json"]
    #树形ID hash
    target_hash = {}
    #遍历学生的报告路径，将获取的id进行分类，结构为{学校uid:{班级uid:学生uid}}
    target_pupil_urls.map{|url| 
      target_path = url.split(".json")[0]
      target_path_arr = target_path.split("/")
      target_pupil_uid = target_path_arr[-1]#学生uid
      target_klass_uid = target_path_arr[-3]#班级uid
      target_tenant_uid = target_path_arr[-5]#学校uid

      if target_hash.has_key?(target_tenant_uid)
        if target_hash[target_tenant_uid].has_key?(target_klass_uid)
          target_hash[target_tenant_uid][target_klass_uid] << target_pupil_uid
        else
          target_hash[target_tenant_uid][target_klass_uid] = []
          target_hash[target_tenant_uid][target_klass_uid] << target_pupil_uid
        end
      else
        target_hash[target_tenant_uid] = {}
        if target_hash[target_tenant_uid].has_key?(target_klass_uid)
          target_hash[target_tenant_uid][target_klass_uid] << target_pupil_uid
        else
          target_hash[target_tenant_uid][target_klass_uid] = []
          target_hash[target_tenant_uid][target_klass_uid] << target_pupil_uid
        end
      end
    }.compact

    
    #父表格数据，各个学校内的绑定情况
    result_arr = []#内容为[{name:学校名,total_tenant:校长数量,binded_tenant:校长绑定数量,total_teacher:教师数量,..}]
    #子表格数据,内容为key是学校名称，value是学校内各班级绑定情况
    result_hash = {}#内容为{学校名:[{name:班级名,total_teacher:教师数量,binded_teacher:教师绑定数量,total_pupil:学生数量,..}]}
    #遍历id hash获取结果
    target_hash.each{|k,v|
      tenant_hash = {}#每个学校内的绑定情况hash
      tena = Tenant.where(uid: k).first#根据学校uid获取学校
      tenant_name = tena.blank? ? k : tena.name_cn
      tenant_hash['name'] = tenant_name
      tenant_hash['total_pupils'] = 0#初始化数量为0
      tenant_hash['binded_pupils'] = 0
      tenant_hash['total_teachers'] = 0
      tenant_hash['binded_teachers'] = 0
      result_hash[tenant_name] = []#key为学校名称，value为各个班级的绑定情况组成的数组
      tenant_teacher_ids = []#学校的老师id为各个班级的老师id加在一起再去除重复
      v.map{|k1,v1|
        class_hash = {}#每个班级内的绑定情况
        loc = Location.where(uid: k1).first#根据班级uid获取班级
        class_hash['name'] = loc.blank? ? k1 : Common::Locale::i18n("dict.#{loc.classroom}")

        target_pupil_ids = Pupil.joins(:user).where(uid: v1).pluck(:id).uniq#根据学生uid获取学生的user_id
        target_teacher_ids = loc.blank? ? [] : loc.teachers.map{|item| item[:teacher].user_id.to_i}.uniq#班级内所有老师的user_id
        tenant_teacher_ids += target_teacher_ids

        binded_pupil_number = get_binded_num(target_pupil_ids)#获取绑定的学生数量
        binded_teacher_number = get_binded_num(target_teacher_ids)#获取绑定的老师数量

        class_hash["total_pupils"] = v1.length
        tenant_hash['total_pupils'] += v1.length
        class_hash["binded_pupils"] = binded_pupil_number
        tenant_hash['binded_pupils'] += binded_pupil_number

        class_hash["total_teachers"] = target_teacher_ids.size
        class_hash["binded_teachers"] = binded_teacher_number
        result_hash[tenant_name] << class_hash
      }
      target_tenant_ids = TenantAdministrator.where(tenant_uid: k).pluck(:user_id).uniq
      binded_tenant_number = get_binded_num(target_tenant_ids)

      binded_tenant_teacher_number = get_binded_num(tenant_teacher_ids.uniq)

      tenant_hash['total_teachers'] = tenant_teacher_ids.uniq.size
      tenant_hash['binded_teachers'] = binded_tenant_teacher_number
      tenant_hash['total_tenant'] = target_tenant_ids.size
      tenant_hash['binded_tenant'] = binded_tenant_number
      result_arr << tenant_hash
    }
    return result_hash,result_arr
  end

  def get_binded_num(user_ids)
    #两个join找到所有绑定微信的主账号，where是满足身份账号在user_ids内的主账号
    master_ids = User.joins(:wx_user_mappings, :groups_as_child).where("user_links.child_id in (:child_ids) ", child_ids: user_ids).pluck(:id)
    #这批主账号绑定的子账号
    binded_wx_user = UserLink.where(parent_id: master_ids).pluck(:child_id)
    #身份账号与绑定主账号的子账号的交集，就是这批所绑定的账号
    return (user_ids&binded_wx_user).size
  end

  #统计测试报告情况
  def get_report_state
    @test_state = self.bank_test_state.attributes.clone unless self.bank_test_state.blank?
    @group_state = self.bank_test_group_state.map{|group_state|
      group_state = group_state.attributes.clone
    } unless self.bank_test_group_state.blank?
   
    self.bank_test_group_state.delete_all unless self.bank_test_group_state.blank?
    self.bank_test_state.destroy unless self.bank_test_state.blank?

    state_hash = {
      :area_rid => self.area_rid,
      :bank_test_id => self._id,
      :total_num => 0
    }
    begin
      top_group = self.report_top_group.blank? ? "project" : self.report_top_group
      index = Common::Report::Group::ListArr.index(top_group)

      _report_warehouse_path = Common::Report::WareHouse::ReportLocation + "reports_warehouse/tests/"
      nav_arr = Dir[_report_warehouse_path + self._id + '/' + top_group + "/**/**/nav.json"]
      nav_arr += Dir[_report_warehouse_path + self._id + '/nav.json']

      # path = "/reports_warehouse/tests/"
      # nav_arr = Dir[Common::Report::WareHouse::ReportLocation + Dir::pwd + path + self._id + '/' + top_group + "/**/**/nav.json"]
      # nav_arr += Dir[Common::Report::WareHouse::ReportLocation + Dir::pwd + path + self._id + '/nav.json']

      nav_arr.each{|nav_path|
        group_state_hash = {
          :area_rid => self.area_rid,
          :bank_test_id => self._id,
        }
        target_nav_h = get_report_hash(nav_path)
        target_nav_count = target_nav_h.values[0].size
        target_path = nav_path.split("/nav.json")[0]
        target_path_arr = target_path.split("/")
        target_group = (Common::Report::Group::ListArr[0..index] - target_path_arr)[-1]
        group_hash = group_state_hash.merge!({"#{target_group}_num".to_sym => target_nav_count})
        if target_group == 'klass'
          group_hash.merge!({:tenant_uid => target_path_arr[-1]})
        end
        
        if target_group == 'pupil'
          group_hash.merge!({:tenant_uid => target_path_arr[-3],:klass_uid => target_path_arr[-1]})
        end
        group_state = Mongodb::BankTestGroupState.new(group_hash)
        group_state.save!

        state_hash["total_num"] = state_hash["total_num"].to_i + target_nav_count
        state_hash["#{target_group}_num"] = state_hash["#{target_group}_num"].to_i + target_nav_count
      }
      test_state = Mongodb::BankTestState.new(state_hash)
      test_state.save!
      return test_state
    rescue Exception => e
      single_rollback
      raise
    end
  end

  #保存测试
  def save_test params
    paper = Mongodb::BankPaperPap.where(_id: params[:paper_uid]).first 
    union_test = Mongodb::UnionTest.where(_id: params[:id]).first
    params[:tenant_uids] = union_test.tenant_uids
    params[:paper_uid] = paper._id.to_s
    params[:checkpoint_system_rid] = paper.checkpoint_system_rid
    params[:union_test_id] = union_test.id

    phase_arr = %w{ phase1 phase2 phase3 }
    error_index = 0
    begin
      phase_arr.each_with_index do |phase, index|
        error_index = index
        send("save_bank_test_#{phase}",params)
      end
    rescue Exception => e
      phase_arr = phase_arr[0..error_index].reverse
      phase_arr.each_with_index do |phase, index|
        send("save_bank_test_#{phase}_rollback")
      end
      raise e
    end
  end

  #创建测试第一步，关联学校
  def save_bank_test_phase1 params
    begin
      if self.bank_test_tenant_links.blank?
        params[:tenant_uids].each {|tenant|
          bank_test_tenant_link = Mongodb::BankTestTenantLink.new(tenant_uid: tenant, bank_test_id: self._id, tenant_status: Common::Test::Status::New)
          bank_test_tenant_link.save   
        }
      end
    rescue Exception => e
      raise e.message 
    end
  end

  #创建测试第二步，保存测试
  def save_bank_test_phase2 params
    begin
      self.update_attributes({
        :name => params[:name]||params[:paper_uid] + "_" +Common::Locale::i18n("activerecord.models.bank_test"),
        :user_id => params[:user_id],
        :start_date => params[:start_date],
        :quiz_date => params[:quiz_date]||Time.now,
        :union_test_id => params[:union_test_id],
        :test_type => params[:test_type],
        :checkpoint_system_rid => params[:checkpoint_system_rid],
        :bank_paper_pap_id => params[:paper_uid],
        :test_status => Common::Test::Status::New
      })
    rescue Exception => e
      raise e.message 
    end
  end

  #创建测试第三步，TaskList
  def save_bank_test_phase3 params
    begin
      if self.bank_test_task_links.blank?
        [Common::Task::Type::ImportResult, Common::Task::Type::CreateReport].each{|tk|
          tkl = TaskList.new({
            :name => self.id.to_s + "_" + Common::Locale::i18n("tasks.type." + tk),
            :task_type => tk,
            #:pap_uid => id.to_s,
            :status => Common::Task::Status::InActive
          })
          tkl.save!
          tkl_link = Mongodb::BankTestTaskLink.new(:task_uid => tkl.uid)
          tkl_link.save!
          self.bank_test_task_links.push(tkl_link)
        }
      end
    rescue Exception => e
      raise e.message 
    end
  end

  #第一步异常调用
  def save_bank_test_phase1_rollback
    self.bank_test_tenant_links.destroy_all
  end

  #第二步异常调用
  def save_bank_test_phase2_rollback
    self.destroy
  end

  #第三步异常调用
  def save_bank_test_phase3_rollback
    self.tasks.destroy_all
    self.bank_test_task_links.destroy_all
  end





  #测试状态回退
  def roll_back params
    case params[:back_to]
    when Common::Test::Status::New
      if [Common::Test::Status::New].include?(self.test_status)
        return false
      else
        #删除身份验证表
        IdentityMapping.where(test_id: self.id.to_s).destroy_all
        #删除报告文件
        # del_report_file
        #去除资源锁
        del_lock
        #删除job_lists
        self.tasks.each{|task|
          task.job_lists.destroy_all
        }
        #修改学校状态
        self.bank_test_tenant_links.each{ |t|
          t.update(tenant_status: Common::Test::Status::New)
        }
        #修改测试状态
        self.update(test_status: Common::Test::Status::New)
      end
    when Common::Test::Status::ScoreImported
      if [Common::Test::Status::ReportGenerating,Common::Test::Status::ReportCompleted].include?(self.test_status)
        #删除报告文件
        # del_report_file
        #去除资源锁
        del_lock
        #删除job_lists
        task = self.tasks.by_task_type("create_report").first
        task.job_lists.destroy_all
        #修改测试状态
        self.update(test_status: Common::Test::Status::ScoreImported)
      else
        return false
      end
    end
  end

  #删除报告文件
  def del_report_file
    _report_warehouse_path = Common::Report::WareHouse::ReportLocation + "reports_warehouse/tests/" + self._id.to_s
    FileUtils.rm_rf(_report_warehouse_path)
  end

  #去除资源锁
  def del_lock
    Common::TkLock::force_release_lock_paper_test_qzp_ckp self.id
  end

  #回退单个学校
  def rollback_tenant tenant_uid
    tenant_link = Mongodb::BankTestTenantLink.where(bank_test_id: self.id,tenant_uid: tenant_uid).first
    tenant_link.update(tenant_status: Common::Test::Status::New)
    if self.test_status == Common::Test::Status::ScoreImported
      self.update(test_status: Common::Test::Status::ScoreImporting)
    end 
  end

  #忽略单个学校
  def ignore_tenant tenant_uid
    tenant_link = Mongodb::BankTestTenantLink.where(bank_test_id: self.id,tenant_uid: tenant_uid).first
    tenant_link.update(tenant_status: Common::Test::Status::Ignore)
  end

  #生成二维码
  def create_rqrcode
    file_path = Common::Report::WareHouse::ReportLocation + "reports_warehouse/tests/" + self._id.to_s + '/'
    FileUtils.mkdir_p(file_path) unless File.exists?(file_path)  
    file_name = self._id.to_s + '.png'
    code_hash = {
      test_id: self.id.to_s
    }
    qrcode = RQRCode::QRCode.new(code_hash.to_json.to_s)
    
    qrcode.to_img.resize(400, 400).save(file_path + file_name)
    return file_path + file_name
  end
  #删除上传的成绩文件以及相关信息
  # def delete_score_uploads
  #   score_path = ""
  #   if self.score_uploads.present?
  #     self.score_uploads.each {|su| 
  #       if su.filled_file.current_path.present?
  #         score_path = su.filled_file.current_path.split("/")[0..-2].join("/")
  #       elsif su.empty_file.current_path.present?
  #         score_path = su.empty_file.current_path.split("/")[0..-2].join("/")
  #       end
  #       if score_path
  #         FileUtils.rm_rf(score_path)
  #       end
  #       bank_link_user_rollback su
  #       su.delete
  #     }
  #   end
  # end

  #回滚状态
  def single_rollback
    self.bank_test_group_state.delete_all unless self.bank_test_group_state.blank?
    self.bank_test_state.destroy unless self.bank_test_state.blank?
    
    Mongodb::BankTestState.new(@test_state).save! unless @test_state.blank?
    @group_state.each{|group| Mongodb::BankTestGroupState.new(group).save!} unless @group_state.blank?
  end

  #读取文件内容
  def get_report_hash file_path
    fdata = File.open(file_path, 'rb').read
    JSON.parse(fdata) 
  end

  def add_value_to_item
    #获得地区信息
    area_h = {
      :province_rid => "",
      :city_rid => "",
      :district_rid => ""
    }
    target_area = Area.where(rid: self.area_rid).first
    if target_area
      area_h[:province_rid] = target_area.pcd_h[:province][:rid]
      area_h[:city_rid] = target_area.pcd_h[:city][:rid]
      area_h[:district_rid] = target_area.pcd_h[:district][:rid]
    end
    h = {
      "uid" => self._id.to_s,
      "tenant_uids[]" => self.bank_test_tenant_links.map(&:tenant_uid),
      "tenants_range" => self.bank_test_tenant_links.nil? ? "" : self.tenants.map(&:name_cn).join("<br>"),
      "paper_name" => self.bank_paper_pap.present? ? self.bank_paper_pap.heading : nil,
      "paper_id" => self.bank_paper_pap_id.to_s,
      "down_allow" => self.score_uploads.present? ? true : false
    }
    h.merge!(area_h)
    h.merge!(self.attributes)
    h["start_date"]= self.start_date.strftime("%Y-%m-%d %H:%M:%S") if self.start_date.present?
    h["quiz_date"]= self.quiz_date.strftime("%Y-%m-%d %H:%M:%S") if self.quiz_date.present?
    h["dt_update"]=h["dt_update"].strftime("%Y-%m-%d %H:%M:%S")
    return h
  end


  def save_bank_test params
    area_ird = params[:province_rid] unless params[:province_rid].blank?
    area_rid = params[:city_rid] unless params[:city_rid].blank?
    area_rid = params[:district_rid] unless params[:district_rid].blank?
    paramsh = {
      :name => params[:name],
      :start_date => params[:start_date],
      :quiz_date => params[:quiz_date],
      :quiz_type => params[:quiz_type],
      :is_public => params[:is_public],
      :checkpoint_system_rid => params[:checkpoint_system_rid],
      :area_rid => area_rid
    }
    update_attributes(paramsh)
    bank_test_tenant_links.destroy_all
    params[:tenant_uids].each {|tenant|
        bank_test_tenant_link = Mongodb::BankTestTenantLink.new(tenant_uid: tenant, bank_test_id: self._id)
        bank_test_tenant_link.save
    }
  end

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

  def user_ids
    bank_test_user_links.map(&:user_id)
  end

  def users
    User.where(id: user_ids)
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
      # target_pap = self.bank_paper_pap
      # paper_h = JSON.parse(target_pap.paper_json)
      # unless paper_h["information"]["tenants"].blank?
      #   paper_h["information"]["tenants"].each_with_index{|item, index|
      #     if tenant_uids.include?(item["tenant_uid"])
      #       paper_h["information"]["tenants"][index]["tenant_status"] = status_str
      #       paper_h["information"]["tenants"][index]["tenant_status_label"] = Common::Locale::i18n("tests.status.#{status_str}")
      #     end
      #   }
      #   target_pap.update(:paper_json => paper_h.to_json)
      # end 
    rescue Exception => ex
      logger.debug ex.message
      logger.debug ex.backtrace
    end
  end

  def checkpoint_system
    CheckpointSystem.where(rid: self.checkpoint_system_rid).first
  end

  #学生与测试关联 保存学生基本信息
  def combine_bank_user_link params
    if self.bank_paper_pap.orig_file_id
      fu = FileUpload.where(id: self.bank_paper_pap.orig_file_id).first
    else
      fu = FileUpload.new
    end
    fu.user_base = params[:file_name]
    fu.save!
    self.bank_paper_pap.orig_file_id = fu.id
    self.bank_paper_pap.save!
    paper_xlsx = Roo::Excelx.new(fu.user_base.current_path)
    tenant_uids.each do |t_uid|
      user_base_excel = Axlsx::Package.new
      user_base_sheet = user_base_excel.workbook.add_worksheet(:name => "user_base")
      paper_xlsx.sheet(0).each do |row|
        next if row[1] != t_uid
        user_base_sheet.add_row(row, :types => [:string,:string,:string,:string,:string,:string,:string,:string,:string,:string,:string,:string,:string])
      end
      file_path = Rails.root.to_s + "/tmp/#{self._id.to_s}.xlsx"
      user_base_excel.serialize(file_path)
      if score_uploads.where(tenant_uid: t_uid).size > 0
        su = score_uploads.where(tenant_uid: t_uid).first
      else
        su = ScoreUpload.new(tenant_uid: t_uid, test_id: self._id.to_s)
      end
      su.user_base = Pathname.new(file_path).open
      su.save!
      File.delete(file_path)
      if bank_test_tenant_links.where(tenant_uid: t_uid).first.blank?
        Mongodb::BankTestTenantLink.new(bank_test_id: self._id.to_s, tenant_uid: t_uid).save!
      end
      target_tenant = Tenant.where(uid: t_uid).first
      tenant_area = target_tenant.area
      if bank_test_area_links.where(area_uid: tenant_area.uid).first.blank?
        Mongodb::BankTestAreaLink.new(bank_test_id: self._id.to_s, area_uid: tenant_area.uid).save!
      end
    end
    begin    
      score_uploads.each do |su|
        bank_link_user su
      end
    rescue Exception => e
      score_uploads.each do |su|
        bank_link_user_rollback su
      end
    end
  end

  #生成用户信息
  def bank_link_user su
    error_message = ""
    error_status = false
    target_tenant = Tenant.where(uid: su.tenant_uid).first
    target_area = target_tenant.area
    teacher_username_in_sheet = []
    pupil_username_in_sheet = []
    location_list = {}
    user_info_xlsx = Roo::Excelx.new(su.user_base.current_path)
    out_excel = Axlsx::Package.new
    wb = out_excel.workbook

    head_teacher_sheet = wb.add_worksheet(:name => Common::Locale::i18n('scores.excel.head_teacher_password_title'))
    teacher_sheet = wb.add_worksheet(:name => Common::Locale::i18n('scores.excel.teacher_password_title'))
    pupil_sheet = wb.add_worksheet(:name => Common::Locale::i18n('scores.excel.pupil_password_title'))
    new_user_sheet = wb.add_worksheet(:name => Common::Locale::i18n('scores.excel.new_user_title'), state: :hidden)

    head_teacher_sheet.add_row Common::Uzer::UserAccountTitle[:head_teacher]
    teacher_sheet.add_row Common::Uzer::UserAccountTitle[:teacher]
    pupil_sheet.add_row Common::Uzer::UserAccountTitle[:pupil]
    new_user_sheet.add_row Common::Uzer::UserAccountTitle[:new_user]

    cols = {
      :tenant_name => 0,
      :tenant_uid => 1,
      :grade => 2,
      :grade_code => 3,
      :classroom =>4,
      :classroom_code => 5,
      :head_teacher_name => 6,
      :head_teacher_number => 7,
      :subject_teacher_name => 8,
      :subject_teacher_number => 9,
      :subject_teacher_subject => 10,
      :pupil_name => 11,
      :pupil_number => 12,
      :pupil_gender => 13
    }
    begin   
      if user_info_xlsx.sheet(0).last_row.present? 
        user_info_xlsx.sheet(0).each{|row|
          next if target_tenant.blank?

          grade_pinyin = Common::Locale.hanzi2pinyin(row[cols[:grade]].to_s.strip)
          klass_pinyin = Common::Locale.hanzi2pinyin(row[cols[:classroom]].to_s.strip)
          klass_value = Common::Klass::List.keys.include?(klass_pinyin.to_sym) ? klass_pinyin : row[cols[:classroom]].to_s.strip
          target_tenant_uid = target_tenant.try(:uid)

          cells = {
            :grade => grade_pinyin,
            :xue_duan => Common::Grade.judge_xue_duan(grade_pinyin),
            :classroom => klass_value,
            :head_teacher => row[cols[:head_teacher_name]].to_s.strip,
            :head_teacher_number => row[cols[:head_teacher_number]].to_s.strip,
            :teacher => row[cols[:subject_teacher_name]].to_s.strip,
            :teacher_number => row[cols[:subject_teacher_number]].to_s.strip,
            :pupil_name => row[cols[:pupil_name]].to_s.strip,
            :stu_number => row[cols[:pupil_number]].to_s.strip,
            :sex => row[cols[:pupil_gender]].to_s.strip
          }
          loc_h = { :tenant_uid => target_tenant_uid }
          loc_h.merge!({
            :area_uid => target_area.uid,
            :area_rid => target_area.rid
          }) if target_area

          loc_h[:grade] = cells[:grade]
          loc_h[:classroom] = cells[:classroom]
          loc_key = target_tenant_uid + cells[:grade] + cells[:classroom]
          if location_list.keys.include?(loc_key)
            loc = location_list[loc_key]
          else
            loc = Location.new(loc_h)
            loc.save!
            bank_test_location_link = Mongodb::BankTestLocationLink.new(bank_test_id: self._id.to_s, loc_uid: loc.uid).save!
            location_list[loc_key] = loc
          end
          user_row_arr = []
          # 
          # create teacher user 
          #
          head_tea_h = {
            :loc_uid => loc.uid,
            :tenant_uid => target_tenant_uid,
            :name => cells[:head_teacher],
            :classroom => cells[:classroom],
            # :subject => @target_paper.subject,
            :head_teacher => true,
            :user_name =>Common::Uzer.format_user_name([
              target_tenant.number,
              #Common::Subject::Abbrev[@target_paper.subject.to_sym],
              cells[:head_teacher_number],
              Common::Locale.hanzi2abbrev(cells[:head_teacher])
            ])
          }
          user_row_arr = Common::Uzer.format_user_password_row(Common::Role::Teacher, head_tea_h)
          unless teacher_username_in_sheet.include?(user_row_arr[0])
            head_teacher_sheet.add_row(user_row_arr[0..-2], :types => [:string,:string,:string,:string,:string,:string,:string]) 
            teacher_username_in_sheet << user_row_arr[0]
            Common::Uzer.link_user_and_bank_test(user_row_arr[0], self._id.to_s)
            if !user_row_arr[-1] 
              user = User.find_by(name: user_row_arr[0])
              if user.present?
                new_user_sheet.add_row([user.id, self._id.to_s, user_row_arr[0], user_row_arr[1]], :types => [:string,:string,:string,:string,:string,:string,:string,:string])
              end
            end          
          end
          #
          # create pupil user
          #
          tea_h = {
            :loc_uid => loc.uid,
            :tenant_uid => target_tenant_uid,
            :name => cells[:teacher],
            :classroom => cells[:classroom],
            :subject => row[cols[:subject_teacher_subject]],
            :head_teacher => false,
            :user_name => Common::Uzer.format_user_name([
              target_tenant.number,
              #Common::Subject::Abbrev[@target_paper.subject.to_sym],
              cells[:teacher_number],
              Common::Locale.hanzi2abbrev(cells[:teacher])
            ])
          }
          user_row_arr = Common::Uzer.format_user_password_row(Common::Role::Teacher, tea_h)
          unless teacher_username_in_sheet.include?(user_row_arr[0])
            teacher_sheet.add_row(user_row_arr[0..-2], :types => [:string,:string,:string,:string,:string,:string,:string]) 
            teacher_username_in_sheet << user_row_arr[0]
            Common::Uzer.link_user_and_bank_test(user_row_arr[0], self._id.to_s)          
            if !user_row_arr[-1]
              user = User.where(name: user_row_arr[0]).first
              if user.present?
                new_user_sheet.add_row([user.id, self._id.to_s, user_row_arr[0], user_row_arr[1]], :types => [:string,:string,:string,:string,:string,:string,:string,:string])
              end          
            end 
          end

          # #
          # # create pupil user
          # #
          pup_h = {
            :loc_uid => loc.uid,
            :tenant_uid => target_tenant_uid,
            :name => cells[:pupil_name],
            :stu_number => cells[:stu_number],
            :grade => cells[:grade],
            :classroom => cells[:classroom],
            :subject => row[cols[:subject_teacher_subject]],
            :sex => Common::Locale.hanzi2pinyin(cells[:sex]),
            :user_name => Common::Uzer.format_user_name([
              target_tenant.number,
              cells[:stu_number],
              Common::Locale.hanzi2abbrev(cells[:pupil_name])
            ])
          }
          user_row_arr = Common::Uzer.format_user_password_row(Common::Role::Pupil, pup_h)
          unless pupil_username_in_sheet.include?(user_row_arr[0])
            pupil_sheet.add_row(user_row_arr[0..-2], :types => [:string,:string,:string,:string,:string,:string,:string,:string]) 
            pupil_username_in_sheet << user_row_arr[0]
            Common::Uzer.link_user_and_bank_test(user_row_arr[0], self._id.to_s)          
            if !user_row_arr[-1] 
              user = User.find_by(name: user_row_arr[0])
              if user.present?
                new_user_sheet.add_row([user.id, self._id.to_s, user_row_arr[0], user_row_arr[1]], :types => [:string,:string,:string,:string,:string,:string,:string,:string])
              end
            end 
          end
        }
      end
    rescue Exception => e
      error_message = e.message
      error_status = true
    ensure 
      file_path = Rails.root.to_s + "/tmp/#{self._id.to_s}_bank_test_password.xlsx"
      out_excel.serialize(file_path)
      su.usr_pwd_file = Pathname.new(file_path).open
      su.save!
      File.delete(file_path)
    end
    raise error_message if error_status
  end

  #删除 关联的用户 及相关信息
  def bank_link_user_rollback su
    if su.usr_pwd_file
      user_info_xlsx = Roo::Excelx.new(su.usr_pwd_file.current_path)
      if user_info_xlsx.sheet(3).last_row.present? 
        user_info_xlsx.sheet(3).each_with_index do |row,index|
          next if index == 0
          user = User.where(id: row[0]).first
          #user.role_obj.destroy
          user.destroy if user
        end
        if bank_test.bank_test_user_links.present?
          bank_test.bank_test_user_links.destroy_all
        end
        if bank_test.locations.present?
          bank_test.locations.destroy_all
          bank_test.bank_test_location_links.destroy_all
        end
        if bank_test.bank_test_area_links.present?
          bank_test.bank_test_area_links.destroy
        end
        if bank_test.bank_test_tenant_links.present?
          bank_test.bank_test_tenant_links.destroy_all
        end
      end
      su.remove_usr_pwd_file!
      su.save!
    end   
  end

  def is_report_completed?
    self.test_status == Common::Test::Status::ReportCompleted
  end

  ###私有方法###
  private

    def clear_old_test_state
      self.bank_test_group_state.delete_all unless self.bank_test_group_state.blank?
      self.bank_test_state.destroy unless self.bank_test_state.blank?
    end

    # 随机生成6位外挂码，默认生成码以"___"（三个下划线）开头
    # 
    def generate_ext_data_path
      if self.ext_data_path.blank?
        self.ext_data_path = loop do
          random_str = Common::Test::ExtDataPathDefaultPrefix
          random_str += Common::Test::ExtDataPathLength.times.map{ Common::Test::ExtDataCodeArr.sample }.join("")
          break random_str unless self.class.where(ext_data_path: random_str).exists?
        end
      end
    end
end
