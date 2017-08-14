# -*- coding: UTF-8 -*-

class Mongodb::BankPaperPap

  include Mongoid::Document
  include Mongodb::MongodbPatch
  include SwtkLockPatch
  
  attr_accessor :current_user_id
  attr_accessor :test_associated_tenant_uids, :status, :target_area, :old_status, :old_tenant_links, :old_paper_outline_arr

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  # has_many :bank_paperlogs, class_name: "Mongodb::BankPaperlog"
  # has_many :bank_pap_ptgs, class_name: "Mongodb::BankPapPtg"
  has_and_belongs_to_many :bank_quiz_qizs, class_name: "Mongodb::BankQuizQiz", dependent: :delete 
  has_and_belongs_to_many :bank_qizpoint_qzps, class_name: "Mongodb::BankQizpointQzp"
  has_many :bank_pap_cats, class_name: "Mongodb::BankPapCat", dependent: :delete 
  has_many :bank_tests, class_name: "Mongodb::BankTest", dependent: :delete
  has_many :online_tests, class_name: "Mongodb::OnlineTest", dependent: :delete
  has_many :paper_outlines, class_name: "Mongodb::PaperOutline",dependent: :delete
  has_many :bank_tnt_paps, class_name: "Mongodb::BankTntPap",foreign_key: "pap_uid", dependent: :delete
  has_many :bank_tea_paps, class_name: "Mongodb::BankTeaPap",foreign_key: "pap_uid", dependent: :delete
  has_many :bank_pup_paps, class_name: "Mongodb::BankPupPap",foreign_key: "pap_uid", dependent: :delete

  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_subject, ->(subject) { where(subject: subject) if subject.present? }
  scope :by_grade, ->(grade) { where(grade: grade) if grade.present? }
  scope :by_status, ->(status) { where(paper_status: status) if status.present? }
  scope :by_keyword, ->(keyword) { any_of({heading: /#{keyword}/}, {subheading: /#{keyword}/}) if keyword.present? }
  scope :by_province, ->(province) { where(province: province) if province.present? }
  scope :by_city, ->(city) { where(city: city) if city.present? }
  scope :by_district, ->(district) { where(district: district) if district.present? }
  scope :by_tenant, ->(t_uid){ where(tenant_uid: t_uid) if t_uid.present? }

  #validates :caption, :region, :school,:chapter,length: {maximum: 200}
  #validates :subject, :type, :version,:grade, :purpose, :levelword, length: {maximum: 50}

#  field :uid, type: String
#  field :caption, type: String
  field :name, type: String
  field :order, type: String
  field :heading, type: String
  field :subheading, type: String
  field :province, type: String
  field :city, type: String
  field :district, type: String
  field :school, type: String
  field :subject, type: String
  field :grade, type: String
  field :term, type: String
  field :quiz_type, type: String
  field :quiz_date, type: DateTime
  field :text_version, type: String
  field :node_uid, type: String
  field :quiz_range,type: String
  field :quiz_duration, type: Float
  field :levelword, type: String
  field :levelword2, type: String
  field :score, type: Float
  field :checkpoint_system_rid, type: String
  
#  field :orig_paper, type: String
#  field :orig_answer, type: String
  field :orig_file_id, type: String
  field :score_file_id, type: String
  field :paper_html, type: String
  field :answer_html, type: String
  field :ckps_file_id, type: String

  field :user_id, type: String
  field :tenant_uid, type: String
  field :area_uid, type: String

  field :paper_json, type: String
  #
#  field :ckp_source_type, type: String
  #field :paper_saved_json, type: String
  #field :paper_analyzed_json, type: String
  # field :analyze_json, type: String
  field :paper_status, type: String

  #是否可用于测试／在线测试
  field :can_test, type: Boolean, default: false
  field :can_online_test, type: Boolean, default: false

  #是否为空
  field :is_empty, type: Boolean, default: false

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({province: 1, city: 1, district:1}, {background: true})
  index({_id: 1}, {background: true})
  index({user_id: 1}, {background: true})
  index({grade: 1}, {background: true})
  index({subject: 1}, {background: true})
  index({paper_status: 1}, {background: true})
  index({dt_update:-1},{background: true})

  ########类方法定义：begin#######
  class << self
    #导出试卷分析
    def export_pap_ckpz_qzps params
      out_path = Rails.root.to_s + "/public/ckpz_qzps.xlsx"
      pap_ids = params[:id_arr]

      out_excel = Axlsx::Package.new
      wb = out_excel.workbook

      wb.add_worksheet name: "Data" do |sheet|

        cell_style = {
          :title => wb.styles.add_style(
            :bg_color => "FF00F7", 
            :border => { 
                :style => :thin, 
                :color => "00" 
              },
              :fg_color => "000000", 
              :sz => 12, 
              :alignment => { 
                :horizontal=> :center 
              }
            )
        }
        # 标题
        title_row_arr = ["paper","dimension", "level", "layer", "index", "count", "score"]
        sheet.add_row(
            title_row_arr,
            :style => title_row_arr.size.times.map{|item| cell_style[:title]}
        )

        pap_ids.each{|pap_id|
          target_paper = Mongodb::BankPaperPap.where(id: pap_id).first
          next if target_paper.blank?
          data_row_base_arr = [target_paper.heading]
          ckps_qzps = target_paper.associated_checkpoints()
          ckps_qzps.map{|item| item[1]}.flatten.each{|item|
            data_row_arr = [
              item[:dimesion],
              item[:high_level],
              item[:rid].length/3,
              item[:checkpoint],
              item[:qzp_count],
              item[:qzps_full_score_total]
            ]
            sheet.add_row(data_row_base_arr + data_row_arr)
          }
        }
      end
      out_excel.serialize(out_path)
      return out_path
    end

    #获取试卷信息
    def get_list params
      params[:page] = params[:page].blank?? Common::SwtkConstants::DefaultPage : params[:page]
      params[:rows] = params[:rows].blank?? Common::SwtkConstants::DefaultRows : params[:rows]
      conditions = {}
      %w{paper_status grade subject term heading}.each{|attr|
         conditions[attr] = Regexp.new(params[attr]) unless params[attr].blank? 
       } 
      result =  self.only(:_id,:heading,:tenant_uid,:school,:subject,:grade,:term,:dt_update,:paper_status, :is_empty)
                    .where(conditions)
                    .order("dt_update desc")
                    .page(params[:page]).per(params[:rows])
      paper_result = []
      result.each_with_index do |item|
        h = {
          "uid" => item._id.to_s,
          # "heading" => item.heading.nil?? "" : item.heading,
          # "paper_status" => item.paper_status,  
          "school" => item.tenant.nil?? "": item.tenant.name_cn,
          # "subject" => item.subject.nil?? "": item.subject,
          # "grade" => item.grade.nil?? "": item.grade,
          # "term" => item.term.nil?? "": item.term
        }

        h.merge!(item.attributes)
        h["subject_label"] = Common::Locale::i18n("dict.#{h["subject"]}")
        h["grade_label"] = Common::Locale::i18n("dict.#{h["grade"]}")
        h["term_label"] = Common::Locale::i18n("dict.#{h["term"]}")
        h["status_label"] = Common::Locale::i18n("papers.status.#{h["paper_status"]}")
        h["has_bank_test"] = item.bank_tests.present?
        paper_result << h
      end
      return paper_result, self.count
    end

    def ckp_weights_modification args={}
      if !args[:subject].blank? && !args[:dimesion].blank? && !args[:weights].blank? && !args[:difficulty].blank?
        case args[:subject]
        when "shu_xue"
          result = args[:weights]*Common::CheckpointCkp::DifficultyModifierShuXue[args[:dimesion].to_sym][args[:difficulty].to_sym]
        else
          result = args[:weights]*Common::CheckpointCkp::DifficultyModifier[args[:dimesion].to_sym][args[:difficulty].to_sym]
        end
      elsif !args[:weights].blank?
        result = args[:weights]*Common::CheckpointCkp::DifficultyModifier[:default]
      else
        result = 1
      end
    end

    def get_column_arr filter, col_str

      map = %Q{
        function(){
          emit({#{col_str}: this.#{col_str}}, {});
        }
      }

      reduce = %Q{
        function(key, values) {
        }
      }

      result = Mongodb::BankPaperPap.where(filter).map_reduce(map, reduce).out(inline: true).to_a
      result.map{|a| a[:_id][col_str.to_sym] if a[:_id][col_str.to_sym].is_a? String}
    end

    def get_paper_status_count filter
      result = {}

      map = %Q{
        function(){
          emit({paper_status: this.paper_status}, {count: 1});
        }
      }

      reduce = %Q{
        function(key, values) {
          var result = {
            count: 0
          };
          values.forEach(function(value){
            result.count += value.count;
          });
          return result;
        }
      }
      arr = Mongodb::BankPaperPap.where(filter).map_reduce(map, reduce).out(inline: true).to_a
      arr.each{|a| result[a["_id"]["paper_status"]] = a["value"]["count"].to_i if a["_id"]["paper_status"].is_a? String}
      result
    end

    def region(papers)
      map = %Q{
          function(){
            emit({province: this.province, city: this.city}, {district: this.district})
          }
        }

      reduce = %Q{
        function(key, values) {
          var result = {district: []};
          values.forEach(function(value) {  
            result.district.push(value.district);     
          });
          return result;
        }
      }
     
      region = []
      provinces = papers.distinct(:province)
      region_data =  papers.map_reduce(map, reduce).out(inline: true)

      provinces.each do |province|
        city = []
        # region_data.select{|r| city << {name: r["_id"]["city"], label: Common::Locale::i18n('area.' + r["_id"]["city"]), area: [*r["value"]["district"]].uniq.map{|m| {name: m, label: Common::Locale::i18n('area.' + m)} }} if r["_id"]["province"] == province }
        # region << {name: province, label: Common::Locale::i18n('area.' + province), city: city}
        region_data.select{ |r| city << {name: r["_id"]["city"], label: r["_id"]["city"], area: Array(r["value"]["district"]).uniq.map{|m| {name: m, label: m} }} if r["_id"]["province"] == province }
        region << {name: province, label: province, city: city}
     
      end
      region
    end

    def get_pap pap_uid
      target_pap = Mongodb::BankPaperPap.where(_id: pap_uid).first
      #判断状态是否需要更新
      case target_pap.paper_status
      when Common::Paper::Status::Analyzed,Common::Paper::Status::ScoreImporting
        if !target_pap.bank_tests[0].blank? && !target_pap.bank_tests[0].tenant_list.blank?
          unless target_pap.bank_tests[0].tenant_list.map{|a| a[:tenant_status] == Common::Paper::Status::ScoreImported}.include?(false)
            paper_json_h = JSON.parse(target_pap.paper_json)
            paper_json_h["information"]["paper_status"] = Common::Paper::Status::ScoreImported
            target_pap.update({
              :paper_status => Common::Paper::Status::ScoreImported,
              :paper_json => paper_json_h.to_json
            })
          end
        end
      else
        #do nothing
      end
      target_pap
    end

    ##############################
    #            微信             #
    ##############################
    # 任意检索一个试卷
    # 参数：
    #   grade: 年级
    #   term: 学期
    #   subject: 学科
    #
    def get_a_paper params_h
      where(params_h).sample
    end

  end
  ########类方法定义：end#######

  def save_pap params
    result = false
    begin
      # 锁定
      #

      params[:pap_uid] = id.to_s
      ##############################
      #地理位置信息
      current_user = Common::Uzer.get_user current_user_id
      target_tenant = Common::Uzer.get_tenant current_user_id
      test_associated_tenant_uids = []
      if current_user.is_project_administrator?
        target_area = Area.where(rid: current_user.role_obj.area_rid).first
        params[:information][:province] = target_area.pcd_h[:province][:name_cn]
        params[:information][:city] = target_area.pcd_h[:city][:name_cn]
        params[:information][:district] = target_area.pcd_h[:district][:name_cn]
        params[:information][:school] = Common::Locale::i18n("tenants.types.xue_xiao_lian_he")
        test_associated_tenant_uids = params[:information][:tenants].map{|item| item[:tenant_uid]} unless params[:information][:tenants].blank?
      else
        target_area = Area.get_area params[:information]
        if target_tenant
          params[:information][:province] = target_tenant.area_pcd[:province_name_cn]
          params[:information][:city] = target_tenant.area_pcd[:city_name_cn]
          params[:information][:district] = target_tenant.area_pcd[:district_name_cn]
          params[:information][:school] = target_tenant.name_cn
          test_associated_tenant_uids = [target_tenant.uid]
        end
      end
      raise if test_associated_tenant_uids.blank?
      ##############################

      ##############################
      #临时处理，伴随试卷保存
      #创建测试
      ext_data_path = (params[:test] && params[:test][:ext_data_path]) ? params[:test][:ext_data_path] : ""
      if self.bank_tests.blank?
        pap_test = Mongodb::BankTest.new({
          :name => self._id.to_s + "_" +Common::Locale::i18n("activerecord.models.bank_test"),
          :user_id => current_user_id,
          :quiz_date => Time.now,
          :ext_data_path => ext_data_path,
          :bank_paper_pap_id => self.id.to_s
        })
        pap_test.save!
        # self.bank_tests = [pap_test]
        # save!
      else
        self.bank_tests[0].update( ext_data_path: ext_data_path )
        self.bank_tests[0].bank_test_tenant_links.destroy_all if !self.bank_tests[0].bank_test_tenant_links.blank?
      end

      test_associated_tenant_uids.each{|tnt_uid|
        test_tenant_link = Mongodb::BankTestTenantLink.new({
          :tenant_uid => tnt_uid
        })
        test_tenant_link.save!
        self.bank_tests[0].bank_test_tenant_links.push(test_tenant_link)
      } 

      ##############################
      #试卷状态更新
      status = Common::Paper::Status::None
      if params[:information][:heading] && params[:bank_quiz_qizs].blank?
        status = Common::Paper::Status::New
      elsif params[:information][:heading] && params[:bank_quiz_qizs] && self.bank_quiz_qizs.blank?
        status = Common::Paper::Status::Editting  
      else
        # do nothing
      end
      params["information"]["paper_status"] = status

      #测试各Tenant的状态更新
      params = update_test_tenants_status(params,
        Common::Test::Status::NotStarted,
        self.bank_tests[0].bank_test_tenant_links.map(&:tenant_uid)
      )

      ##############################
      #Task List创建： 上传成绩， 生成报告
      params["information"]["tasks"] = params["information"]["tasks"] || {}
      if params["information"]["tasks"].blank?
        self.bank_tests[0].bank_test_task_links.destroy_all
        [Common::Task::Type::ImportResult, Common::Task::Type::CreateReport].each{|tk|
          tkl = TaskList.new({
            :name => id.to_s + "_" + Common::Locale::i18n("tasks.type." + tk),
            :task_type => tk,
            #:pap_uid => id.to_s,
            :status => Common::Task::Status::InActive
          })
          tkl.save!
          tkl_link = Mongodb::BankTestTaskLink.new(:task_uid => tkl.uid)
          tkl_link.save!
          params["information"]["tasks"][tk] = tkl.uid
          bank_tests[0].bank_test_task_links.push(tkl_link)
        }
      end

      ##############################
      #试卷大纲信息保存
      params["information"]["paper_outline"] = params["information"]["paper_outline"] || {}
      paper_outline_arr = []

      if params["information"]["paper_outline_edittable"]
        paper_outline_str = params["information"]["paper_outline"]
        paper_outline_arr = paper_outline_str.split("\n")
        paper_outline_arr.map!{|item| item.gsub(/\s+$/,'')}
        rid_arr = []
        last_level = 0
        paper_outline_arr.map!{|item|
          item_name = item.gsub(/^\++/,'')
          item_level = item.scan(/\+{4}/).size + 1
          rid = rid_arr[item_level] || -1
          rid += 1
          rid_arr[item_level] = rid
          item_rid = rid_arr[1..item_level].map{|r| r.to_s.rjust(3, "0") }.join("")
          {
            :name => item_name,
            :rid => item_rid,
            :order => item_rid,
            :level => item_level,
            :is_end_point => false,
            :bank_paper_pap_id => self.id
          }
        }
        paper_outline_arr.map{|item|
          rid_re = Regexp.new "^(#{item[:rid]}).{3,}" 
          item["is_end_point"] = true if paper_outline_arr.find{|o| o[:rid] =~ rid_re }.blank?
        }
        paper_outlines.destroy_all
        Mongodb::PaperOutline.collection.insert_many(paper_outline_arr)
      end


      #试卷保存
      self.update_attributes({
        :user_id => current_user_id || "",
        :area_uid => target_area.nil?? "" : target_area.uid,
        :tenant_uid => target_tenant.nil?? "" : target_tenant.uid,
        :heading => params[:information][:heading] || "",
        :subheading => params[:information][:subheading] || "",
        :orig_file_id => params[:orig_file_id] || "",
        :paper_json => params.to_json || "",
        :paper_html => params[:paper_html] || "",
        :answer_html => params[:answer_html] || "",
        :paper_status => status
      })

      #有异常，抛出
      # result = false unless self.errors.messages.empty?
      #   raise SwtkErrors::SavePaperHasError.new(I18n.t("papers.messages.save_paper.debug", :message => self.errors.messages)) 
      # end
      result = self.errors.messages.empty?
    rescue Exception => ex
      self.errors.add(:base, ex.message)
      result = false
    ensure
      # 解锁
      #
      return result
    end
  end

  def save_pap_rollback
    #delete bank_test_tenant_links
    #delete bank_test
    #delete test task list
    #delete bank_paper_pap
  end

  def submit_pap params
    params = params.deep_dup

    self.update_attributes({
      :order => params[:order] || "",
      :heading => params[:information][:heading] || "",
      :subheading => params[:information][:subheading] || "",
      :province => params[:information][:province] || "",
      :city => params[:information][:city] || "",
      :district => params[:information][:district] || "",
      :school => params[:information][:school] || "",
      :subject => params[:information][:subject].blank? ? "": params[:information][:subject][:name],
      :checkpoint_system_rid => params[:information][:checkpoint_system].blank? ? "": params[:information][:checkpoint_system][:name],
      :grade => params[:information][:grade].blank? ? "": params[:information][:grade][:name],
      :term => params[:information][:term].blank? ? "": params[:information][:term][:name],
      :quiz_type => params[:information][:quiz_type] || "",
      :quiz_date => params[:information][:quiz_date] || "",
      :text_version => params[:information][:text_version].blank? ? "":params[:information][:text_version][:name],
      :node_uid => params[:information][:node_uid] || "",
      :quiz_duration => params[:information][:quiz_duration] || 0.00,
      :levelword2 => params[:information][:levelword2] || "",
      :score => params[:information][:score] || 0.00,
#     :paper_json => params.to_json || ""
#        :paper_status => status
    })
    unless self.errors.messages.empty?
      raise SwtkErrors::SavePaperHasError.new(I18n.t("papers.messages.save_paper.debug", :message => self.errors.messages)) 
    end
   
    # update node catalogs of paper
    #begin
    if params[:bank_node_catalogs]
      params[:bank_node_catalogs].each_with_index{|cat,index|
        cat = Mongodb::BankPapCat.new(pap_uid: self._id.to_s, cat_uid: cat[:id])
        cat.save
        if cat.errors.messages.empty?
          params[:bank_node_catalogs][index][:id]=cat._id.to_s
        else
          raise SwtkErrors::SavePaperHasError.new(I18n.t("papers.messages.save_paper.debug", :message => cat.errors.messages))
        end
      }
    end

    # save all quiz
    #begin
    if params[:bank_quiz_qizs]
      # 所有得分点的题顺数组
      qizpoint_order_arr = params[:bank_quiz_qizs].map{|qiz| qiz["bank_qizpoint_qzps"] }.flatten.map{|qzp| qzp["order"]}
      params[:bank_quiz_qizs].each_with_index{|quiz,index|
        # store quiz
        qzp_arr = []
        qiz = Mongodb::BankQuizQiz.new
        
        quiz["subject"] = subject
        # 单题的试卷中递增题顺
        quiz["asc_order"] = index + 1
        # 所有得分点的题顺数组
        quiz["qizpoint_order_arr"] = qizpoint_order_arr

        qzp_arr = qiz.save_quiz quiz
        if qiz.errors.messages.empty?
          params[:bank_quiz_qizs][index][:id]=qiz._id.to_s
          unless qzp_arr.empty?
            qzp_arr.each_with_index{|qzp_uid,qzp_index|
              params[:bank_quiz_qizs][index][:bank_qizpoint_qzps][qzp_index][:id] = qzp_uid
            }
          end
        else
          raise SwtkErrors::SavePaperHasError.new(I18n.t("papers.messages.save_paper.debug", :message => qiz.errors.messages))
        end
        self.bank_quiz_qizs.push(qiz)
      }
    end

    status = Common::Paper::Status::Editted
    params["information"]["paper_status"] = status
    self.update_attributes({
      :paper_status => status,
      :paper_json => params.to_json || ""
    })
  end

  def submit_pap_rollback
    #
    #
  end

  def save_ckp params
    self.status = Common::Paper::Status::Analyzing
    #return result if params[:infromation].blank?
    old_paper_h = JSON.parse(self.paper_json).clone

    paper_h = JSON.parse(self.paper_json)
    paper_h["information"]["paper_status"] = status
    paper_h["bank_quiz_qizs"] = params[:bank_quiz_qizs]

    begin      
      self.update_attributes({
        :paper_json => paper_h.to_json || "",
        :paper_status => status
      })
    rescue Exception => e
      save_ckp_rollback old_paper_h
    end
  end

  def save_ckp_rollback paper_h
     self.update_attributes({
       :paper_json => paper_h.to_json || "",
      :paper_status => self.status
     })
  end

  def submit_ckp params
    status = Common::Paper::Status::Analyzed
    if params[:bank_quiz_qizs]
      params[:bank_quiz_qizs].each{|param|
        # get quiz
        current_qiz = Mongodb::BankQuizQiz.where(_id: param[:id]).first
        param["bank_qizpoint_qzps"].each{|bqq|
          # get quiz point
          qiz_point = Mongodb::BankQizpointQzp.where(_id: bqq[:id]).first
          if bqq["bank_checkpoints_ckps"]
            current_qiz.save_qzp_all_ckps qiz_point,bqq
          end
        }
      }
    end

    paper_h = JSON.parse(self.paper_json)
    paper_h["bank_quiz_qizs"] = params[:bank_quiz_qizs]

    #测试各Tenant的状态更新
    paper_h = update_test_tenants_status(
      paper_h,
      Common::Test::Status::Analyzed,
      self.bank_tests[0].bank_test_tenant_links.map(&:tenant_uid)
    )

    paper_h["information"]["paper_status"] = status
    self.update_attributes({
      :paper_json => paper_h.to_json || "",
      :paper_status => status
    })
    
    #update qizpoint ckps, paper outline json
    qzps = bank_quiz_qizs.map{|qiz| qiz.bank_qizpoint_qzps }.flatten
    qzps.each{|qzp|
      qzp.format_ckps_json
      qzp.format_paper_outline_json
    }
  end

  def submit_ckp_rollback

  end

  def bank_node_catalogs
    cat_uids = self.bank_pap_cats.map{|cat| cat.uid }
    cat_uids.map{|uid|
      BankNodeCatalog.where(uid: uid) 
    }
  end

  def ordered_qzps
    bank_quiz_qizs.map{|qiz| 
      qiz.bank_qizpoint_qzps 
    }.flatten.sort{|a,b|
      a_order_converted = a.order.gsub(/(\))/,"").split("(").map{|item| item.rjust(5,"0")}.join("")
      b_order_converted = b.order.gsub(/(\))/,"").split("(").map{|item| item.rjust(5,"0")}.join("")
      Common::Locale.mysort(a_order_converted,b_order_converted) 
    }
  end

  # 获取试卷关联指标的树形结构数据
  # 用于:
  #   1) 查看试卷指标<->试题关联
  #   2) 报告模版生成
  #
  def associated_checkpoints uniq_flag=false
    result = Hash.new
    dimesion_arr = Common::CheckpointCkp::Dimesions[checkpoint_system.sys_type.to_sym]
    dimesion_arr.each{|dim|
      result[dim] = []
    }
    qzps = bank_quiz_qizs.map{|qiz| qiz.bank_qizpoint_qzps }.flatten
    qzps.each{|qzp| 
      qzp.bank_checkpoint_ckps.each{|qzp_ckp|
        next unless qzp_ckp

        #ckp_ancestors = BankRid.get_all_higher_nodes(qzp_ckp.families,qzp_ckp)
        ckps_arr = []
        ckps_arr.unshift(qzp_ckp)
        while !qzp_ckp.parent.nil?
          qzp_ckp = qzp_ckp.parent
          ckps_arr.unshift(qzp_ckp)
        end
        ckps_arr.each{|ckp|
          index = result[ckp.dimesion].find_index{|item| item[:uid] == ckp.uid}
          if index.nil?
            item = {
              :uid => ckp.uid,
              :order => ckp.sort,
              :rid => ckp.rid,
              :dimesion => ckp.dimesion,
              :checkpoint => ckp.checkpoint,
              :high_level => ckp.high_level,
              :advice => ckp.advice,
              :is_entity => ckp.is_entity,
              :qzps_full_score_total => qzp.score.nil?? 0 : qzp.score,
              :qzps => [qzp.id.to_s],
              :qzp_count => 1
            }
            result[ckp.dimesion] << item
          else
            next if uniq_flag && !result[ckp.dimesion][index][:qzps].find_index{|item| item == qzp.id.to_s}.blank?
            result[ckp.dimesion][index][:qzps_full_score_total] += qzp.score.nil?? 0 : qzp.score
            result[ckp.dimesion][index][:qzps].push(qzp.id.to_s)
            result[ckp.dimesion][index][:qzp_count] += 1
          end
        }
      }
    }

    result.each{|k,v|
      result[k] = v.sort{|a,b| Common::CheckpointCkp::compare_rid(a[:order], b[:order])}
    }
    return result
  end

  # 获取试卷关联大纲的树形结构数据
  #
  def associated_outlines uniq_flag=false
    result = []
    qzps = bank_quiz_qizs.map{|qiz| qiz.bank_qizpoint_qzps }.flatten
    qzps.each{|qzp| 
      qzp_outline = qzp.paper_outline
      next unless qzp_outline
      outline_arr = qzp_outline.ancestors.to_a + [qzp_outline]

      outline_arr.each{|outline|
        index = result.find_index{|item| item[:id] == outline.id.to_s}
        if index.nil?
          result << {
            :id => outline.id.to_s,
            :order => outline.rid,
            :rid => outline.rid,
            :level => outline.level,
            :name => outline.name,
            :is_end_point => outline.is_end_point,
            :qzps_full_score_total => qzp.score.nil?? 0 : qzp.score,
            :qzps => [qzp.id.to_s],
            :qzp_count => 1
          }
        else
          next if uniq_flag && !result[index][:qzps].find_index{|item| item == qzp.id.to_s}.blank?
          result[index][:qzps_full_score_total] += qzp.score.nil?? 0 : qzp.score
          result[index][:qzps].push(qzp.id.to_s)
          result[index][:qzp_count] += 1
        end
      }
    }

    result.sort!{|a,b| Common::CheckpointCkp::compare_rid(a[:order], b[:order])}
    return result
  end

  # 返回得分点与指标的Mapping数组
  #
  # [return]: Array
  def qzps_checkpoints_mapping ckp_level=1
    result = []
    return result if bank_quiz_qizs.blank?
    qzps = ordered_qzps
    return result if qzps.blank?
    dimesion_arr = Common::CheckpointCkp::Dimesions[checkpoint_system.sys_type.to_sym]

    target_level = ckp_level
    target_level = -1 if ckp_level > Common::Report::CheckPoints::DefaultLevelEnd
    pap_checkpoint_model = qzps[0].bank_checkpoint_ckps[0].class
    qzps.each_with_index{|qzp, index|
      qzp.format_ckps_json if qzp.ckps_json.blank?
      ckp_h = JSON.parse(qzp.ckps_json)
      
      target_level_ckp_h = Common::CheckpointCkp.ckp_types_loop(dimesion_arr) {|dimesion|
        ckp_h[dimesion].map{|ckp|
          ckp_uid = ckp.keys[0].split("/")[target_level]
          target_ckp = pap_checkpoint_model.where(uid: ckp_uid).first
          {
            "uid" => ckp_uid,
            "rid" => ckp.values[0]["rid"].split("/")[target_level],
            "weights" => ckp.values[0]["weights"].split("/")[target_level],
            "checkpoint" => target_ckp.blank?? nil : target_ckp.checkpoint
          }
        }.uniq
      }
      item = {
        "qzp_id" => qzp.id.to_s,
        "qzp_order" => (index+1).to_s,
        "qzp_system_order" => qzp.order,
        "qzp_custom_order" => qzp.custom_order,
        "qzp_type" => qzp.type,
        "ckps" => target_level_ckp_h
      }
      item.merge!({
        "outline" => {
          "id" => qzp.paper_outline.id.to_s,
          "order" => qzp.paper_outline.rid.to_s,
          "name" => qzp.paper_outline.name.to_s
        }
      }) if qzp.paper_outline
      result << item
    }
    return result
  end
  

  # def task_lists
  #   TaskList.where(:pap_uid => id.to_s)
  # end

  #
  # used for report
  # checkpoints and qizpoints mapping
  #
  # def get_pap_ckps_qzp_mapping
  #   result = {
  #     :knowledge => {:level1=>{}, :level2=>{}},
  #     :skill => {:level1=>{}, :level2=>{}},
  #     :ability => {:level1=>{}, :level2=>{}}
  #   }
  #   qzpoints = self.bank_quiz_qizs.map{|a| a.bank_qizpoint_qzps}.flatten
  #   qzpoints.each{|qzp|
  #     qzp.bank_checkpoint_ckps.each{|ckp|
  #       next unless ckp
  #       levels = [*1..Common::Report::CheckPoints::Levels]
  #       levels.each{|lv|
  #         # search current level checkpoint
  #         if ckp.is_a? BankCheckpointCkp
  #           lv_ckp = BankCheckpointCkp.where("node_uid = '#{self.node_uid}' and rid = '#{ckp.rid.slice(0, Common::SwtkConstants::CkpStep*lv)}'").first
  #         elsif ckp.is_a? BankSubjectCheckpointCkp
  #           xue_duan = Common::Grade.judge_xue_duan(self.grade)
  #           lv_ckp = BankSubjectCheckpointCkp.where("category = '#{xue_duan}' and rid = '#{ckp.rid.slice(0, Common::SwtkConstants::CkpStep*lv)}'").first
  #         end
  #         temp_arr = result[ckp.dimesion.to_sym]["level#{lv}".to_sym][lv_ckp.checkpoint.to_sym] || []
  #         result[ckp.dimesion.to_sym]["level#{lv}".to_sym][lv_ckp.checkpoint.to_sym] = temp_arr
  #         result[ckp.dimesion.to_sym]["level#{lv}".to_sym][lv_ckp.checkpoint.to_sym] << { 
  #           :ckp_uid => ckp.uid,
  #           :weights => ckp.weights,
  #           :qzp_uid => qzp._id.to_s
  #         }
  #       }
  #     }
  #   }
  #   return result
  # end

  # def get_dimesion_ckp_total_score ckps_qzps
  #   total_score = {
  #     :knowledge => 0, 
  #     :skill => 0, 
  #     :ability => 0
  #   }

  #   ckp_total_score = {
  #      :knowledge => {:level1 =>{}, :level2=>{}},
  #      :skill => {:level1 =>{}, :level2=>{}},
  #      :ability => {:level1 =>{}, :level2=>{}}
  #   }

  #   ckps_qzps.each{|dimesion_key, dimesions|
  #     dimesions.each{|level_key, levels|
  #       levels.each{|lv_ckp, values|
  #         ckp_total_score[dimesion_key.to_sym][level_key.to_sym][lv_ckp.to_sym] = 0
  #         values.each{|value|
  #           qzp = Mongodb::BankQizpointQzp.where(_id: value[:qzp_uid]).first
  #           if qzp
  #             total_score[dimesion_key.to_sym] += qzp.score*value[:weights]
  #             ckp_total_score[dimesion_key.to_sym][level_key.to_sym][lv_ckp.to_sym] += qzp.score*value[:weights]
  #           end
  #         }
  #       }
  #     }
  #   }
  #   return total_score, ckp_total_score
  # end

  #未来要实现可属于多个tenant
  def tenant
    Tenant.where(uid: self.tenant_uid).first
  end

  # create empty score file
  def generate_empty_score_file
    out_excel = Axlsx::Package.new
    wb = out_excel.workbook
 
    wb.add_worksheet name: "使用说明", state: :hidden  do |sheet|

    end

    # list sheet
    grade_number = 0
    wb.add_worksheet name: "grade_list", state: :hidden  do |sheet|
      #grade 
      Common::Grade::List.each{|k,v|
        sheet.add_row [v]
      }
      grade_number = Common::Grade::List.size
    end

    # list sheet
    classroom_number = 0
    wb.add_worksheet name: "classroom_list", state: :hidden  do |sheet|
      #classroom 
      Common::Klass::List.each{|k,v|
        sheet.add_row [v]
      }
      classroom_number = Common::Klass::List.size
    end

    # list sheet
    wb.add_worksheet name: "sex_list", state: :hidden   do |sheet|
      #grade 
      Common::Locale::SexList.each{|k,v|
        sheet.add_row [v]
      }
    end

    # area sheet
    province_list = []
    province_cell = nil
    city_list = []
    city_cell = nil
    district_list = []
    district_last = nil
    #wb.add_worksheet name: "area_list" , state: :hidden do |sheet|
    wb.add_worksheet name: "area_list", state: :hidden   do |sheet|
      File.open(Rails.root.to_s + "/public/area.txt", "r") do |f|
        f.each_line do |line|
          arr = line.split(" ")
          province_list << arr[0]
          city_list << arr[1]
          district_list << arr[2]
        end
      end
      sheet.add_row province_list.uniq!
      province_cell = sheet.rows.last.cells.last
      sheet.add_row city_list.uniq!
      city_cell = sheet.rows.last.cells.last
      arr = district_list.uniq!
      arr.each{|item|
        sheet.add_row [item]
      }
      district_last=sheet.rows.last
    end

    unlocked = wb.styles.add_style :locked => false
    title_cell = wb.styles.add_style :bg_color => "CBCBCB", 
      :fg_color => "000000", 
      :sz => 14, 
      :alignment => { :horizontal=> :center },
      :border => Axlsx::STYLE_THIN_BORDER#{ :style => :thick, :color =>"000000", :edges => [:left, :top, :right, :bottom] }
    info_cell = wb.styles.add_style :fg_color => "000000", 
      :sz => 14, 
      :alignment => { :horizontal=> :center },
      :border => Axlsx::STYLE_THIN_BORDER
    data_cell = wb.styles.add_style :sz => 14, 
      :alignment => { :horizontal=> :right }, 
      :format_code =>"0.00"

    wb.add_worksheet(:name => Common::Locale::i18n('scores.excel.score_title')) do |sheet|
      sheet.sheet_protection.password = 'forbidden_by_k12ke'

      # row 1
      # location input field
      location_row_arr = [
        Common::Locale::i18n('dict.province'),
        province,
        Common::Locale::i18n('dict.city'),
        city,
        Common::Locale::i18n('dict.district'),
        district,
        Common::Locale::i18n('dict.tenant'),
        school
      ]

      # row 2
      # hidden field
      hidden_title_row_arr = [
        "grade",
        "classroom",
        "head_teacher",
        "teacher_number",
        "subject_teacher",
        "teacher_number",
        "name",
        "pupil_number",
        "sex",
        tenant_uid # 隐藏tenant uid在表格中, version1.0，没什么用先埋下
      ]

      # row 3
      # qizpoint order
      order_row_arr = [
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        Common::Locale::i18n('quizs.order')
      ]

      # row 4
      # title
      title_row_arr = [
        Common::Locale::i18n('dict.grade'),
        Common::Locale::i18n('dict.classroom'),
        Common::Locale::i18n('dict.head_teacher'),
        Common::Locale::i18n('dict.teacher_number'),
        Common::Locale::i18n('dict.subject_teacher'),
        Common::Locale::i18n('dict.teacher_number'),
        Common::Locale::i18n('dict.name'),
        Common::Locale::i18n('dict.pupil_number'),
        Common::Locale::i18n('dict.sex'),
        "#{Common::Locale::i18n('quizs.full_score')}(#{self.score})"
      ]

      # row 4
      # every qizpoint score  
      score_row_arr = title_row_arr.deep_dup
      score_row_arr.pop()
      score_row_arr.push(self.score)

      # quizs = self.bank_quiz_qizs.sort{|a,b| Common::Paper::quiz_order(a.order,b.order) }
      # qiz_order = 0
      # quizs.each{|qiz|
      #   qzps = qiz.bank_qizpoint_qzps.sort{|a,b| Common::Paper::quiz_order(a.order,b.order) }
      #   #全部从1开始升序排知识点，旧排序注释（1/2）
      #   qzp_count = qzps.size
      #   qzps.each_with_index{|qzp, qzp_index|
      #     hidden_title_row_arr.push(qzp._id)
      #     #全部从1开始升序排知识点，旧排序注释（2/2）
      #     #(qzp_count > 1) ? order_row_arr.push(qzp.order.sub(/0*$/, '')) : order_row_arr.push(qiz.order)
      #     qiz_order += 1
      #     #(qzp_count > 1) ? order_row_arr.push(qzp.order.sub(/0*$/, '') + "-#{qiz_order}") : order_row_arr.push(qiz.order + "-#{qiz_order}")
      #     order_row_arr.push(qiz_order)
      #     title_row_arr.push(qzp.score)
      #   }
      # }

      qzps = ordered_qzps
      #全部从1开始升序排知识点，旧排序注释（1/2）
      qzps.each_with_index{|qzp, qzp_index|
        hidden_title_row_arr.push(qzp._id)
        #全部从1开始升序排知识点，旧排序注释（2/2）
        order_row_arr.push((qzp_index + 1))
        title_row_arr.push(qzp.score)
      }

      #sheet.add_row location_row_arr, :style => [title_cell, title_cell, title_cell,unlocked,title_cell,unlocked,title_cell,unlocked]
      sheet.add_row location_row_arr, :style => [title_cell, info_cell, title_cell,info_cell,title_cell,info_cell,title_cell,info_cell]
      # sheet.add_data_validation("B1",{
      #   :type => :list,
      #   :formula1 => "areaList!A1:#{province_cell.r}",
      #   :showDropDown => false,
      #   :showInputMessage => true,
      #   :promptTitle => Common::Locale::i18n('dict.province'),
      #   :prompt => ""
      # })
      # sheet.add_data_validation("D1",{
      #   :type => :list,
      #   :formula1 => "areaList!A2:#{city_cell.r}",
      #   :showDropDown => false,
      #   :showInputMessage => true,
      #   :promptTitle => Common::Locale::i18n('dict.city'),
      #   :prompt => ""
      # })
      # sheet.add_data_validation("F1",{
      #   :type => :list,
      #   :formula1 => "areaList!A3:#{district_last.cells[0].r}",
      #   :showDropDown => false,
      #   :showInputMessage => true,
      #   :promptTitle => Common::Locale::i18n('dict.district'),
      #   :prompt => ""
      # })

      sheet.add_row hidden_title_row_arr
      sheet.column_info.each{|col|
        col.width = nil
      }
      sheet.add_row order_row_arr, :style => title_cell
      sheet.add_row title_row_arr, :style => title_cell
      sheet.rows[1].hidden = true

      cols_count = title_row_arr.size
      empty_row = [] 
      cols_count.times.each{|index|
        empty_row.push("")
      }

      Common::Score::Constants::AllowScoreNumber.times.each{|line|
        sheet.add_row empty_row, :style => unlocked
        sheet.add_data_validation("A#{line+5}",{
          :type => :list,
          :formula1 => "grade_list!A$1:A$#{grade_number}",
          :showDropDown => false,
          :showInputMessage => true,
          :promptTitle => Common::Locale::i18n('dict.grade'),
          :prompt => ""
        })
        sheet.add_data_validation("B#{line+5}",{
          :type => :list,
          :formula1 => "classroom_list!A$1:A$#{classroom_number}",
          :showDropDown => false,
          :showInputMessage => true,
          :promptTitle => Common::Locale::i18n('dict.classroom'),
          :prompt => ""
        })
        sheet.add_data_validation("G#{line+5}",{
          :type => :list,
          :formula1 => "sex_list!A$1:A$3",
          :showDropDown => false,
          :showInputMessage => true,
          :promptTitle => Common::Locale::i18n('dict.sex'),
          :prompt => ""
        })
        cells= sheet.rows.last.cells[10..cols_count].map{|cell| {:key=> cell.r, :value=> title_row_arr[cell.index].to_s}}
        cells.each{|cell|
          sheet.add_data_validation(cell[:key],{
            :type => :decimal,
            :operator => :between, 
            :formula1 => '0', 
            :formula2 => cell[:value], 
            :showErrorMessage => true, 
            :errorTitle => Common::Locale::i18n("scores.messages.error.wrong_input"), 
            :error => Common::Locale::i18n("scores.messages.info.correct_score", :min => 0, :max =>cell[:value]), 
            :showInputMessage => true, 
            :promptTitle => Common::Locale::i18n("scores.messages.warn.score"), 
            :prompt => Common::Locale::i18n("scores.messages.info.correct_score", :min => 0, :max =>cell[:value])
          })
        }
        #sheet.rows.last.cells[0..7].each{|col| col.style = info_cell }
        #sheet.rows.last.cells[8..cols_count].each{|col| col.style = data_cell }
      }

    end

    file_path = Rails.root.to_s + "/tmp/#{self._id.to_s}_empty.xlsx"
    out_excel.serialize(file_path)

    # score_file = Common::PaperFile.create_empty_result_list file_path
    Common::PaperFile.create_empty_result_list({:orig_file_id => orig_file_id, :file_path => file_path})

    # self.update(score_file_id: score_file.id)
    File.delete(file_path)
  end

  # def format_user_name args=[]
  #   #args.join("_")
  #   args.join(Common::Uzer::UserNameSperator)
  # end

  # def format_user_password_row role,params_h
  #   row_data = {
  #     Common::Role::Teacher.to_sym => {
  #       :username => params_h[:user_name],
  #       :password => "",
  #       :name => params_h[:name],
  #       :report_url => "",
  #       :op_guide => Common::Locale::i18n('reports.op_guide_details'),
  #       :tenant_uid => params_h[:tenant_uid]
  #     },
  #     Common::Role::Pupil.to_sym => {
  #       :username => params_h[:user_name],
  #       :password => "",
  #       :name => params_h[:name],
  #       :stu_number => params_h[:stu_number],
  #       :report_url => "",#Common::SwtkConstants::MyDomain + "/reports/new_square?username=",
  #       :op_guide => Common::Locale::i18n('reports.op_guide_details'),
  #       :tenant_uid => params_h[:tenant_uid]
  #     }
  #   }

  #   params_h[:tenant_uid] = (tenant.nil?? "":tenant.uid) if params_h[:tenant_uid].blank?

  #   ret = User.add_user params_h[:user_name],role, params_h

  #   target_username = ""
  #   if (ret.is_a? Array) && ret.empty?
  #     row_data[role.to_sym][:password] = Common::Locale::i18n("scores.messages.info.old_user")
  #     row_data[role.to_sym][:report_url] = generate_url
  #     target_username = ret[0]
  #   elsif (ret.is_a? Array) && !ret.empty?
  #     row_data[role.to_sym][:password] = ret[1]
  #     row_data[role.to_sym][:report_url] = generate_url
  #     target_username = ret[0]
  #   else
  #     row_data[role.to_sym][:password] = Common::Locale::i18n("scores.messages.error.add_user_failed")
  #   end
    
  #   associate_user_and_pap role, target_username if (ret.is_a? Array)
  #   return row_data[role.to_sym].values
  # end

  # def associate_user_and_pap role, username
  #   target_user = User.where(name: username).first
  #   return false unless target_user
  #   case role
  #   when "pupil"
  #     target_pupil = target_user.pupil
  #     return false unless target_pupil
  #     pup_uid = target_pupil.uid
  #     bpp = Mongodb::BankPupPap.new
  #     bpp.save_pup_pap pup_uid, self._id.to_s
  #   when "teacher"
  #     target_teacher = target_user.teacher
  #     return false unless target_teacher
  #     tea_uid = target_teacher.uid
  #     btp = Mongodb::BankTeaPap.new
  #     btp.save_tea_pap tea_uid, self._id.to_s
  #   end
  #   return true
  # end

  # def generate_url
  #   return Common::SwtkConstants::MyDomain 
  # end

  def is_completed?
    paper_status == Common::Paper::Status::ReportCompleted
  end

  def update_test_tenants_status params,status_str,tenant_uids=[]
    #测试各Tenant的状态更新
    self.bank_tests[0].bank_test_tenant_links.each{|t|
      t.update(:tenant_status => status_str) if tenant_uids.include?(t[:tenant_uid])
    }
    return params if params.blank? || !params.keys.include?("information")
    params["information"]["tenants"].each_with_index{|item, index|
      if tenant_uids.include?(item["tenant_uid"])
        params["information"]["tenants"][index]["tenant_status"] = status_str
        params["information"]["tenants"][index]["tenant_status_label"] = Common::Locale::i18n("tests.status.#{status_str}")
      end
    } unless params["information"]["tenants"].blank?
    return params
  end

  # 获取大纲列表
  #
  def outline_list
    paper_outlines.map{|item|
      ancestors = paper_outlines.find_all{|o| item.ancestor_rids.include?(o.rid) }
      {id: item.id.to_s, name: item.name, is_end_point: item.is_end_point, path: ancestors.map{|item| "/" + item.name}.join("") + "/" + item.name }
    }.unshift({id: nil, name: nil, is_end_point: "true", path: "" })
  end

  # => ###############################################################
  # =>  save_pap_plus 知识点拆分
  # => ###############################################################
  def save_pap_plus params
    result = false
    phase_arr = %w{phase1 phase2 phase3 phase4 phase5}
    error_index = 0
    self.status = Common::Paper::Status::None
    begin
      # 锁定
      #

      params[:pap_uid] = id.to_s
      ##############################
      #地理位置信息
      current_user = Common::Uzer.get_user current_user_id
      target_tenant = Common::Uzer.get_tenant current_user_id
      test_associated_tenant_uids = []
      if current_user.is_project_administrator?
        target_area = Area.where(rid: current_user.role_obj.area_rid).first
        params[:information][:province] = target_area.pcd_h[:province][:name_cn]
        params[:information][:city] = target_area.pcd_h[:city][:name_cn]
        params[:information][:district] = target_area.pcd_h[:district][:name_cn]
        params[:information][:school] = Common::Locale::i18n("tenants.types.xue_xiao_lian_he")
        self.test_associated_tenant_uids = params[:information][:tenants].map{|item| item[:tenant_uid]} unless params[:information][:tenants].blank?
      else
        target_area = Area.get_area params[:information]
        if target_tenant
          params[:information][:province] = target_tenant.area_pcd[:province_name_cn]
          params[:information][:city] = target_tenant.area_pcd[:city_name_cn]
          params[:information][:district] = target_tenant.area_pcd[:district_name_cn]
          params[:information][:school] = target_tenant.name_cn
          self.test_associated_tenant_uids = [target_tenant.uid]
        end
      end
      raise if self.test_associated_tenant_uids.blank?
      ##############################
      phase_arr.each_with_index do |value,index|
        error_index = index
        params = send("save_pap_#{value}", params)
      end 
      result = self.errors.messages.empty?
      self.unlock!
    rescue Exception => ex
      arr = phase_arr[0..error_index].reverse
      arr.each_with_index do |value, index|
        send("save_pap_#{value}_rollback")
      end
      raise ex.message
    # ensure
    #   p result
    #   #解锁
    #   self.unlock!
    #   return result
    end  
  end

  ##############################
  #临时处理，伴随试卷保存
  #创建测试
  def save_pap_phase1 params
    # step1 new_bank_tests
    begin
      if self.bank_tests.blank?
        pap_test = Mongodb::BankTest.new({
          :name => self._id.to_s + "_" +Common::Locale::i18n("activerecord.models.bank_test"),
          :user_id => current_user_id,
          :quiz_date => Time.now,
          :bank_paper_pap_id => self.id.to_s
        })
        pap_test.save!
        # self.bank_tests = [pap_test]
        # save!
      else
        self.old_tenant_links = self.bank_tests[0].bank_test_tenant_links.map(&:tenant_uid)
        self.bank_tests[0].bank_test_tenant_links.destroy_all unless params[:information][:tenants].blank?
      end
      return params
    rescue Exception => e
      raise e.message 
    end   
  end

  ##############################
  #试卷状态更新
  def save_pap_phase2 params
    #更改tenant状态
    begin
      self.test_associated_tenant_uids.each{|tnt_uid|
        test_tenant_link = Mongodb::BankTestTenantLink.new({
          :tenant_uid => tnt_uid
        })
        test_tenant_link.save!
        self.bank_tests[0].bank_test_tenant_links.push(test_tenant_link)
      }
      if params[:information][:heading] && params[:bank_quiz_qizs].blank?
        self.status = Common::Paper::Status::New
      elsif params[:information][:heading] && params[:bank_quiz_qizs] && self.bank_quiz_qizs.blank?
        self.status = Common::Paper::Status::Editting  
      else
        # do nothing
      end
      self.old_status = params["information"]["paper_status"].blank? ? Common::Paper::Status::None : params["information"]["paper_status"]
      params["information"]["paper_status"] = status

      #测试各Tenant的状态更新
      params = update_test_tenants_status(params,
        Common::Test::Status::NotStarted,
        self.bank_tests[0].bank_test_tenant_links.map(&:tenant_uid)
      )
      return params
    rescue Exception => e
      raise e.message 
    end    
  end

  ##############################
  #Task List创建： 上传成绩， 生成报告
  # step3 params["information"]["tasks"]不存在时 创建bank_test_task_links, tasklist
  def save_pap_phase3 params
    begin
      params["information"]["tasks"] = params["information"]["tasks"] || {}
      if params["information"]["tasks"].blank?
        self.bank_tests[0].bank_test_task_links.destroy_all
        [Common::Task::Type::ImportResult, Common::Task::Type::CreateReport].each{|tk|
          tkl = TaskList.new({
            :name => id.to_s + "_" + Common::Locale::i18n("tasks.type." + tk),
            :task_type => tk,
            #:pap_uid => id.to_s,
            :status => Common::Task::Status::InActive
          })
          tkl.save!
          tkl_link = Mongodb::BankTestTaskLink.new(:task_uid => tkl.uid)
          tkl_link.save!
          params["information"]["tasks"][tk] = tkl.uid
          bank_tests[0].bank_test_task_links.push(tkl_link)
        }
      else
        # if bank_tests[0].bank_test_task_links.blank?
        #   [Common::Task::Type::ImportResult, Common::Task::Type::CreateReport].each{|tk|
        #     tkl_link = Mongodb::BankTestTaskLink.new(:task_uid => params["information"]["tasks"][tk])
        #     tkl_link.save!
        #     bank_tests[0].bank_test_task_links.push(tkl_link)
        #   }
        # else
        # end
      end
      return params
    rescue Exception => e
      raise e.message 
    end
  end

  ##############################
  #试卷大纲信息保存
  def save_pap_phase4 params
    begin
      params["information"]["paper_outline"] = params["information"]["paper_outline"] || {}
      paper_outline_arr = []

      if params["information"]["paper_outline_edittable"]
        #备份以前的paperoutlines
        self.old_paper_outline_arr = paper_outlines.map{|a| a.attributes}
        
        paper_outline_str = params["information"]["paper_outline"]
        paper_outline_arr = paper_outline_str.split("\n")
        paper_outline_arr.map!{|item| item.gsub(/\s+$/,'')}
        rid_arr = []
        last_level = 0
        paper_outline_arr.map!{|item|
          item_name = item.gsub(/^\++/,'')
          item_level = item.scan(/\+{4}/).size + 1
          rid = rid_arr[item_level] || -1
          rid += 1
          rid_arr[item_level] = rid
          item_rid = rid_arr[1..item_level].map{|r| r.to_s.rjust(3, "0") }.join("")
          {
            :name => item_name,
            :rid => item_rid,
            :order => item_rid,
            :level => item_level,
            :is_end_point => false,
            :bank_paper_pap_id => self.id
          }
        }
        paper_outline_arr.map{|item|
          rid_re = Regexp.new "^(#{item[:rid]}).{3,}" 
          item["is_end_point"] = true if paper_outline_arr.find{|o| o[:rid] =~ rid_re }.blank?
        }
        paper_outlines.destroy_all
        Mongodb::PaperOutline.collection.insert_many(paper_outline_arr)
      end
      return params  
    rescue Exception => e
      raise e.message 
    end  
  end

  #试卷保存
  # step5 save/update paper
  def save_pap_phase5 params
    begin
      target_tenant = Common::Uzer.get_tenant current_user_id
      self.update_attributes({
        :user_id => current_user_id || "",
        :area_uid => target_area.nil?? "" : target_area.uid,
        :tenant_uid => target_tenant.nil?? "" : target_tenant.uid,
        :heading => params[:information][:heading] || "",
        :subheading => params[:information][:subheading] || "",
        :orig_file_id => params[:orig_file_id] || "",
        :paper_json => params.to_json || "",
        :paper_html => params[:paper_html] || "",
        :answer_html => params[:answer_html] || "",
        :paper_status => self.status
      })
      return params
    rescue Exception => e
      raise e.message 
    end
  end


  #第一步发生异常时调用的回调
  def save_pap_phase1_rollback 
    #delete bank_test
    if bank_tests[0].present?
      old_tenant_links ||= []
      old_tenant_links.each{|tnt_uid|
        test_tenant_link = Mongodb::BankTestTenantLink.new({
          :tenant_uid => tnt_uid
        })
        test_tenant_link.save!
        self.bank_tests[0].bank_test_tenant_links.push(test_tenant_link)
      }
    end
    params = JSON.parse(self.paper_json)
    if params["information"]["tasks"].blank?
      self.bank_tests[0].destroy_all if self.bank_tests[0]
    end

    self.unlock!
    #delete bank_paper_pap    
  end

  #第二步发生的回滚
  def save_pap_phase2_rollback 
    #delete bank_test_tenant_links
    self.bank_tests[0].bank_test_tenant_links.destroy_all if self.bank_tests[0].present? && self.bank_tests[0].bank_test_tenant_links 
  end

  #第三步发生回滚
  def save_pap_phase3_rollback 

    params = JSON.parse(self.paper_json)

    if params["information"]["tasks"].blank?
      self.bank_tests[0].tasks.destroy_all if self.bank_tests[0].present? && self.bank_tests[0].tasks.present?
      #delete test task list
      self.bank_tests[0].bank_test_task_links.destroy_all if self.bank_tests[0].present? && self.bank_tests[0].bank_test_task_links.present?
    end
  end

  #第四步发生回滚
  def save_pap_phase4_rollback 
    params = JSON.parse(self.paper_json)
    if params["information"]["paper_outline_edittable"]
      paper_outlines.destroy_all
      Mongodb::PaperOutline.collection.insert_many(old_paper_outline_arr)
    end

  end

  #第五步发生回滚
  def save_pap_phase5_rollback 
  end

  # => ###############################################################
  # =>  submit_pap_plus 试卷保存拆分
  # => ###############################################################
  def submit_pap_plus params
    params = params.deep_dup
    phase_arr = %w{ phase1 phase2 phase3}
    error_index = 0
    self.old_status = self.paper_status.clone
    begin      
      phase_arr.each_with_index do |phase, index|
        error_index = index
        send("submit_pap_#{phase}")
      end
    rescue Exception => e
      phase_arr = phase_arr[0..error_index].reverse
      phase_arr.each_with_index do |phase, index|
        send("submit_pap_#{phase}_rollback")
      end
      raise SwtkErrors::SavePaperHasError.new(I18n.t("papers.messages.save_paper.debug", :message => e.message))
    end
  end
  #试卷保存1
  def submit_pap_phase1 
     begin 
       #########
       # part 1 根据params 修改paper信息
       #########
      params = JSON.parse(self.paper_json)

      self.update_attributes({
        :order => params["order"] || "",
        :heading => params["information"]["heading"] || "",
        :subheading => params["information"]["subheading"] || "",
        :province => params["information"]["province"] || "",
        :city => params["information"]["city"] || "",
        :district => params["information"]["district"] || "",
        :school => params["information"]["school"] || "",
        :subject => params["information"]["subject"].blank? ? "": params["information"]["subject"]["name"],
        :checkpoint_system_rid => params["information"]["checkpoint_system"].blank? ? "": params['information']['checkpoint_system']['name'],
        :grade => params["information"]["grade"].blank? ? "": params["information"]["grade"]["name"],
        :term => params["information"]["term"].blank? ? "": params["information"]["term"]["name"],
        :quiz_type => params["information"]["quiz_type"] || "",
        :quiz_date => params["information"]["quiz_date"] || "",
        :text_version => params["information"]["text_version"].blank? ? "": params["information"]["text_version"]["name"],
        :node_uid => params["information"]["node_uid"] || "",
        :quiz_duration => params["information"]["quiz_duration"] || 0.00,
        :levelword2 => params["information"]["levelword2"] || "",
        :score => params["information"]["score"] || 0.00,
      })
     rescue Exception => e
       raise e.message       
     end
   
  end
  #试卷保存2
  def submit_pap_phase2 
    begin
      # update node catalogs of paper
      # if params[:bank_node_catalogs]
      #   params[:bank_node_catalogs].each_with_index{|cat,index|
      #     cat = Mongodb::BankPapCat.new(pap_uid: self._id.to_s, cat_uid: cat[:id])
      #     cat.save
      #     params[:bank_node_catalogs][index][:id]=cat._id.to_s
      #   }
      # end
    rescue Exception => e
      raise e.message       
    end

  end
  #试卷保存3
  def submit_pap_phase3 
    begin   
      # save all quiz
      #begin
      params = JSON.parse(self.paper_json)
      if params["bank_quiz_qizs"]
        # 所有得分点的题顺数组    
        qizpoint_order_arr = params["bank_quiz_qizs"].map{|qiz| qiz["bank_qizpoint_qzps"] }.flatten.map{|qzp| qzp["order"]}
        params["bank_quiz_qizs"].each_with_index{|quiz,index|
          # store quiz
          qzp_arr = []
          qiz = Mongodb::BankQuizQiz.new
          quiz["subject"] = subject
          # 单题的试卷中递增题顺
          quiz["asc_order"] = index + 1
          # 所有得分点的题顺数组
          quiz["qizpoint_order_arr"] = qizpoint_order_arr
          qzp_arr = qiz.save_quiz quiz, self.paper_status
          if qiz.errors.messages.empty?
            params["bank_quiz_qizs"][index]["id"] = qiz._id.to_s
            unless qzp_arr.empty?
              qzp_arr.each_with_index{|qzp_uid,qzp_index|
                params["bank_quiz_qizs"][index]["bank_qizpoint_qzps"][qzp_index]["id"] = qzp_uid
              }
            end
          else
            raise qiz.errors.messges
          end          
          self.bank_quiz_qizs.push(qiz)
        }
      end
      status = Common::Paper::Status::Editted
      params["information"]["paper_status"] = status
      self.update_attributes({
        :paper_json => params.to_json || "",
        :paper_status => status
      })
    rescue Exception => e
      raise e.message       
    end
  end
  #试卷保存回滚1
  def submit_pap_phase1_rollback 
    self.update_attributes({
      :order => "",
      :province => "",
      :city => "",
      :district => "",
      :school => "",
      :subject => "",
      :grade => "",
      :term => "",
      :quiz_type => "",
      :quiz_date => "",
      :text_version => "",
      :node_uid => "",
      :quiz_duration => 0.00,
      :levelword2 => "",
      :score => 0.00,
    })
  end
  #试卷保存回滚2
  def submit_pap_phase2_rollback 
    # if params[:bank_node_catalogs]
    #   params[:bank_node_catalogs].each_with_index{|cat,index|
    #       cat = Mongodb::BankPapCat.where(pap_uid: self._id.to_s, cat_uid: cat[:id]).first
    #       cat.destroy if cat.present?
    #   }
    # end
  end
  #试卷保存回滚3
  def submit_pap_phase3_rollback 
    paper_h = JSON.parse(self.paper_json)

    if paper_h["bank_quiz_qizs"]   
      self.bank_quiz_qizs.destroy_all
    end
    old_status = Common::Paper::Status::Editting
    paper_h["information"]["paper_status"] = old_status

    self.update_attributes({
      :paper_status => old_status,
      :paper_json => paper_h.to_json || ""
    })  
  end

  #清空指标
  def save_ckp_all_rollback
    paper_h = JSON.parse(self.paper_json)
    paper_h["bank_quiz_qizs"].each{|qiz| qiz["bank_qizpoint_qzps"].each{|qzp| qzp["bank_checkpoints_ckps"] = "" }}

    self.update_attributes({
      :paper_json => paper_h.to_json || "",
    })
  end

  #保存指标+
  def submit_ckp_plus params
    phase_arr = %w{ phase1 phase2 phase3 phase4 }
    self.status = Common::Paper::Status::Analyzed
    error_index = 0
    begin      
      phase_arr.each_with_index do |phase, index|
        error_index = index
        send("submit_ckp_#{phase}")
      end
    rescue Exception => e
      phase_arr = phase_arr[0..error_index].reverse
      phase_arr.each_with_index do |phase, index|
        send("submit_ckp_#{phase}_rollback")
      end
      raise SwtkErrors::SavePaperHasError.new(I18n.t("papers.messages.save_paper.debug", :message => e.message))
    end
  end

  #保存指标回滚第一步
  def submit_ckp_phase1 
    begin
      paper_h = JSON.parse(self.paper_json)
      if paper_h["bank_quiz_qizs"]
        paper_h["bank_quiz_qizs"].each{|param|
          # get quiz
          current_qiz = Mongodb::BankQuizQiz.where(_id: param["id"]).first
          param["bank_qizpoint_qzps"].each{|bqq|
            # get quiz point
            qiz_point = Mongodb::BankQizpointQzp.where(_id: bqq["id"]).first
            if bqq["bank_checkpoints_ckps"]
              current_qiz.save_qzp_all_ckps qiz_point,bqq
            end
          }
        }
      end
    rescue Exception => e
      raise e.message       
    end
  end

  #保存指标第二步
  def submit_ckp_phase2
    begin
      paper_h = JSON.parse(self.paper_json)    

      #测试各Tenant的状态更新
      paper_h = update_test_tenants_status(
        paper_h,
        Common::Test::Status::Analyzed,
        self.bank_tests[0].bank_test_tenant_links.map(&:tenant_uid)
      )
      paper_h["information"]["paper_status"] = status
      self.update_attributes({
       :paper_json => paper_h.to_json || "",
      })
    rescue Exception => e
      raise e.message
    end
  end

  #保存指标第三步
  def submit_ckp_phase3
    begin      
      self.update_attributes({
        :paper_status => status
      })    
    rescue Exception => e
      raise e.message
    end
  end

  #保存指标第一步
  def submit_ckp_phase4 
    #update qizpoint ckps json
    begin      
      qzps = bank_quiz_qizs.map{|qiz| qiz.bank_qizpoint_qzps }.flatten
      qzps.each{|qzp|
        qzp.format_ckps_json
      }
    rescue Exception => e
      raise e.message
    end
  end

  #保存指标回滚第一步
  def submit_ckp_phase1_rollback
    paper_h = JSON.parse(self.paper_json)
 
    if paper_h["bank_quiz_qizs"]
      paper_h["bank_quiz_qizs"].each{|param|
        # get quiz
        current_qiz = Mongodb::BankQuizQiz.where(_id: param["id"]).first
        param["bank_qizpoint_qzps"].each{|bqq|
          # get quiz point
          Mongodb::BankCkpQzp.where(qzp_uid: bqq["id"]).destroy_all
        }
      }
    end
  end

  #保存指标回滚第二步
  def submit_ckp_phase2_rollback 
    paper_h = JSON.parse(self.paper_json)
    paper_h["information"]["paper_status"] = Common::Paper::Status::Analyzing
    update_test_tenants_status(
      paper_h,
      Common::Paper::Status::None,
      self.bank_tests[0].bank_test_tenant_links.map(&:tenant_uid)
    )
    self.update_attributes({
       :paper_json => paper_h.to_json || "",
    }) 
  end

  #保存指标回滚第三步
  def submit_ckp_phase3_rollback 
    self.update_attributes({
      :paper_status => Common::Paper::Status::Analyzing
    })        
  end
  #保存指标回滚第四步
  def submit_ckp_phase4_rollback 
    qzps = bank_quiz_qizs.map{|qiz| qiz.bank_qizpoint_qzps }.flatten
    qzps.each{|qzp|
      qzp.update_attributes({ckps_json: ""})
    }
  end
  #状态回滚 目标状态，是否保留解析
  def rollback_status target_status, flag
    return false unless %{ editting editted analyzing}.include?(target_status)
    status_hash = Common::Locale::StatusOrder
    status = self.paper_status
    if status_hash[status.to_sym] >= status_hash[target_status.to_sym]
      if target_status != status
        begin
          case status
          when Common::Paper::Status::Editted
            send("submit_pap_rollback")
          when Common::Paper::Status::Analyzing
            if flag == false
              send("save_ckp_all_rollback")
            end
            self.update_attributes({
              :paper_status => Common::Paper::Status::Editted
            }) 
          when Common::Paper::Status::Analyzed, Common::Paper::Status::ScoreImporting, Common::Paper::Status::ScoreImported, Common::Paper::Status::ReportGenerating, Common::Paper::Status::ReportCompleted
            send("submit_ckp_rollback")                                  
          end
          rollback_status target_status, flag
        rescue Exception => e
          raise e.message
          return false
        end
      else
        return true
      end
    else
      return false
    end
  end
  #回滚到正在解析状态
  def submit_ckp_rollback
    phase_arr = %w{ phase1 phase2 phase3 phase4 }
    phase_arr.reverse.each_with_index do |phase, index|
      send("submit_ckp_#{phase}_rollback")
    end  
  end
  #回滚到正在修订状态
  def submit_pap_rollback
    phase_arr = %w{ phase1 phase2 phase3 }
    phase_arr.reverse.each_with_index do |phase, index|
      send("submit_pap_#{phase}_rollback")
    end 
  end


  #删除相关试卷的上传文件，删除试卷及依赖
  def delete_paper_pap
    begin
      if bank_tests[0].present? 
        score_upload = bank_tests[0].score_uploads.by_tenant_uid(self.tenant_uid).first
      else
        score_upload =  ""
      end 

      if self.orig_file_id
        file_upload = FileUpload.where(id: self.orig_file_id).first 
      else
        file_upload = ""
      end

      score_path = ""
      file_path = ""
      if score_upload.present?
        if score_upload.filled_file.current_path.present?
          score_path = score_upload.filled_file.current_path.split("/")[0..-2].join("/")
          FileUtils.rm_rf(score_path)
        end
        score_upload.delete
      end

      if file_upload.present?
        file_path = file_upload.paper_structure.current_path.split("/")[0..-2].join("/")
        FileUtils.rm_rf(file_path)
        file_upload.delete
      end
      self.delete
    rescue Exception => e
      p e.message
      p e.backtrace
      raise SwtkErrors::DeletePaperError.new(I18n.t("papers.messages.delete_paper.debug", :message => e.message))
    end
  end

  def checkpoint_system
    CheckpointSystem.where(rid: self.checkpoint_system_rid).first
  end

  #导入试卷结构
  def import_paper_structure params
    begin 
      file, heading, subheading, rid = params[:file_name], params[:heading], params[:subheading], params[:checkpoint_system_rid]
      order = 1
      point_order = 1
      quiz_qiz = nil
      pjson = {
        :information => {
          :paper_status => "none"
        }
      }
      fu = FileUpload.new
      fu.paper_structure = params[:file_name]
      fu.save!
      self.heading = heading
      self.subheading = subheading
      self.checkpoint_system_rid = rid
      self.orig_file_id = fu.id
      self.is_empty = true
      self.paper_status = "none"
      self.paper_json = pjson.to_json
      self.save!

      file_content = IO.readlines(fu.paper_structure.current_path)
      file_content.each do |line|
        arr = line.split("\n");
        arr.each do |item|
          str = item.chomp
          if str
            arr = str.split(",")
            if str.scan(/\+{4}/).size < 1
              quiz = Mongodb::BankQuizQiz.new
              quiz.order = order
              quiz.asc_order = order
              quiz.custom_order = arr[1]
              quiz.is_empty = true
              quiz.save!
              quiz_qiz = quiz
              point_order = 1
              self.bank_quiz_qizs.push(quiz)
              order += 1
            else
              qizpoint = Mongodb::BankQizpointQzp.new
              qizpoint.asc_order = quiz_qiz.order
              qizpoint.order = "#{quiz_qiz.order}(#{point_order})"
              qizpoint.custom_order = arr[1]
              qizpoint.answer = arr[2]
              qizpoint.score = arr[3]
              qizpoint.is_empty = true
              qizpoint.save!
              quiz_qiz.bank_qizpoint_qzps.push(qizpoint)
              point_order += 1
            end
          end
        end
      end  
    rescue Exception => e
      self.destroy if self.present?
      fu.destroy
      raise e.message
    end
  end

  #导出试卷结构
  # 可选参数 xlsx json
  #retrun 试卷地址 试卷名字
  def export_paper_strucutre export_type
    begin  
      qizpoints = self.bank_quiz_qizs.map {|quiz| quiz.bank_qizpoint_qzps}.flatten
      if self.orig_file_id
        fu = FileUpload.where(id: self.orig_file_id).first
      else
        fu = FileUpload.new
      end 
      ckp = {}
      file_path = ""
      file_name = ""
      bank_subject_checkpoint_ckps = BankSubjectCheckpointCkp.where(checkpoint_system_rid: self.checkpoint_system_rid).order("rid ASC")
      ckp_hash = {}
      if export_type == "xlsx"
        bank_subject_checkpoint_ckps.each do |ckp|
          checkpoint_arr = [ckp.checkpoint]
          if ckp.parent
            p_ckp = ckp.parent
            checkpoint_arr.unshift("++++")
            if p_ckp.parent
              checkpoint_arr.unshift("++++")
            end
          end
          ckp_hash[ckp.uid] = checkpoint_arr.join("")
        end
        out_excel = Axlsx::Package.new
        wb = out_excel.workbook
        file_path = Rails.root.to_s + "/tmp/#{self._id.to_s}_ckp.xlsx"
        wb.add_worksheet name: "ckp_list", state: :hidden do |sheet|
          ckp_hash.each do |key, value|
            sheet.add_row([[value,key].join(",")], :types => [:string])
          end
        end
        wb.add_worksheet name: "题顺" do |sheet|
          qizpoints.each do |point|
            arr = [point.order,point._id.to_s,nil,nil,nil,nil,nil]
            sheet.add_row(arr)
          end
          sheet.column_info[1].hidden = true

          qizpoints.size.times.each {|line|
            area_arr = %W{C D E F G}
            area_arr.each do |area|
              sheet.add_data_validation("#{area}#{line+1}",{
                :type => :list,
                :formula1 => "ckp_list!A$1:A$#{ckp_hash.size}",
                :showDropDown => false,
                :showInputMessage => true,
                :promptTitle => "指标",
                :prompt => ""
              })
            end
          }
        end
        out_excel.serialize(file_path)
        fu.xlsx_structure = Pathname.new(file_path).open
        fu.save!
        self.orig_file_id = fu.id
        self.save!
        File.delete(file_path)
        file_path = fu.xlsx_structure.current_path
        file_name = "#{self._id.to_s}_" + fu.xlsx_structure.filename
      elsif export_type == "json"
        file_path = Rails.root.to_s + "/tmp/#{self._id.to_s}.json"
        json_arr = []
        object_arr = []
        qizpoints.each do |qiz|
          qiz_obj = {
              id: qiz._id.to_s,
              order: qiz.order,
              full_score: qiz.score
            }
          object_arr << qiz_obj
        end
        result = object_arr.to_json
        File.open(file_path, 'w') do |f|
          f << result
        end
        fu.json_structure = Pathname.new(file_path).open
        fu.save!
        self.orig_file_id = fu.id
        self.save!
        File.delete(file_path)
        file_path = fu.json_structure.current_path
        file_name = "#{self._id.to_s}_" + fu.json_structure.filename
      end
      return file_path, file_name
    rescue Exception => e
      raise e.message
    end
  end

  #指标和试卷进行关联
  def combine_paper_structure_checkpoint params
    begin
      if self.orig_file_id
        fu = FileUpload.where(id: self.orig_file_id).first
      else
        fu = FileUpload.new
      end
      fu.combine_checkpoint = params[:file_name]
      fu.save!
      file_path = fu.combine_checkpoint.current_path 
      paper_xlsx = Roo::Excelx.new(file_path)
      paper_xlsx.sheet(1).each do |row|
        score_row = row.compact
        qizpoint = Mongodb::BankQizpointQzp.where(_id: score_row[1]).first
        raise SwtkErrors::SavePaperHasError.new(I18n.t("papers.messages.error.cannot_combine_checkpoint")) if qizpoint.bank_quiz_qiz.bank_paper_paps[0] != self
        Mongodb::BankCkpQzp.where(qzp_uid: score_row[1]).destroy_all
        score_row[2..-1].each do |ckp_str|
          ckp_info_arr = ckp_str.split(',')
          ckp = Mongodb::BankCkpQzp.new
          ckp.save_ckp_qzp score_row[1], ckp_info_arr[1], "BankSubjectCheckpointCkp"
        end
        qizpoint.format_ckps_json
      end
      self.paper_status = "analyzed"
      self.save!    
    rescue Exception => e
      self.paper_status = "none"
      save!
      qizpoints = self.bank_quiz_qizs.map {|quiz| quiz.bank_qizpoint_qzps}.flatten
      qizpoints.each do |qiz|
          Mongodb::BankCkpQzp.where(qzp_uid: qiz._id.to_s).destroy_all
      end
      raise e.message
    end
  end


  #导出试卷三维指标结构
  def export_paper_associated_ckps_file
    target_subject = self.subject
    target_category =  Common::Grade.judge_xue_duan(self.grade)
    
    ckp_objs = BankSubjectCheckpointCkp.where(subject: target_subject, category: target_category)
    qzps = self.bank_quiz_qizs.map{|qiz| qiz.bank_qizpoint_qzps}.flatten

    ckps_file = FileUpload.where(id: self.ckps_file_id).first
    ckps_file = FileUpload.new if ckps_file.blank?

    begin
      out_excel = Axlsx::Package.new
      wb = out_excel.workbook

      wb.add_worksheet name: "Paper Structure" do |sheet|
        sheet.add_row(["PaperID", self._id.to_s, "Paper Name", self.heading])
        sheet.add_row(["Quit Point", "Score", "Dimesion", "Checkpoint Path"])
        qzps.each{|qzp|
          ckps = qzp.bank_checkpoint_ckps
          ckps.each{|ckp|
            next unless ckp
            ckp_ancestors = BankRid.get_all_higher_nodes ckp_objs, ckp
            ckp_path = ckp_ancestors.map{|a| a.checkpoint }.join(" >> ") + ">> #{ckp.checkpoint}"
            sheet.add_row([qzp.order, qzp.score, I18n.t("dict.#{ckp.dimesion}"), ckp_path])
          }
        }
      end
      file_path = Rails.root.to_s + "/tmp/#{self._id.to_s}_ckps_file.xlsx"
      out_excel.serialize(file_path)
      ckps_file.ckps_associated = Pathname.new(file_path).open
      ckps_file.save!
      self.ckps_file_id = ckps_file.id
      self.save!
      File.delete(file_path)
      file_path = ckps_file.ckps_associated.current_path
      file_name = self.heading+'_'+Common::Locale::i18n("activerecord.models.bank_paper_pap")+Common::Locale::i18n("page.quiz.three_dimensiona_digital_analysis")+'.xlsx'

      return file_path, file_name
    rescue Exception => ex
      raise ex.message
    end
  end

end

