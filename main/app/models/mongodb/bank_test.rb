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
  scope :by_public, ->(flag) { where(is_public: flag) }

  field :name, type: String
  field :quiz_type, type: String
  field :start_date, type: DateTime
  field :quiz_date, type: DateTime #默认为截止日期
  field :user_id, type: String
  field :report_version, type: String
  field :ext_data_path, type: String
  field :report_top_group, type: String
  field :checkpoint_system_rid, type: String
  field :is_public, type: Boolean
  field :area_rid, type: String

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
  def bankbank_link_user_rollback su
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


  ###私有方法###
  private

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
