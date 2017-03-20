# -*- coding: UTF-8 -*-

class Mongodb::BankPaperPap

  attr_accessor :current_user_id

  include Mongoid::Document
  include Mongodb::MongodbPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  has_many :bank_paperlogs, class_name: "Mongodb::BankPaperlog"
  has_many :bank_pap_ptgs, class_name: "Mongodb::BankPapPtg"
  has_and_belongs_to_many :bank_quiz_qizs, class_name: "Mongodb::BankQuizQiz", dependent: :delete 
  has_many :bank_quiz_qiz_histories, class_name: "Mongodb::BankQuizQizHistory"
  has_and_belongs_to_many :bank_qizpoint_qzps, class_name: "Mongodb::BankQizpointQzp"
  has_many :bank_qizpoint_qzp_histories, class_name: "Mongodb::BankQizpointQzpHistory"
  has_many :bank_pap_cats, class_name: "Mongodb::BankPapCat", dependent: :delete 
  has_many :bank_paper_pap_pointers, class_name: "Mongodb::BankPaperPapPointer", dependent: :delete
  has_many :bank_tests, class_name: "Mongodb::BankTest"
  has_many :online_tests, class_name: "Mongodb::OnlineTest"

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
  
#  field :orig_paper, type: String
#  field :orig_answer, type: String
  field :orig_file_id, type: String
  field :score_file_id, type: String
  field :paper_html, type: String
  field :answer_html, type: String

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
      self.bank_tests[0].bank_test_tenant_links.destroy_all unless params[:information][:tenants].blank?
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

    ##############################
    #有异常，抛出
    unless self.errors.messages.empty?
      raise SwtkErrors::SavePaperHasError.new(I18.t("papers.messages.save_paper.debug", :message => self.errors.messages)) 
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
      raise SwtkErrors::SavePaperHasError.new(I18.t("papers.messages.save_paper.debug", :message => self.errors.messages)) 
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
          raise SwtkErrors::SavePaperHasError.new(I18.t("papers.messages.save_paper.debug", :message => cat.errors.messages))
        end
      }
    end

    # save all quiz
    #begin
    if params[:bank_quiz_qizs]
      params[:bank_quiz_qizs].each_with_index{|quiz,index|
        # store quiz
        qzp_arr = []
        qiz = Mongodb::BankQuizQiz.new
        quiz["subject"] = subject
        qzp_arr = qiz.save_quiz quiz
        if qiz.errors.messages.empty?
          params[:bank_quiz_qizs][index][:id]=qiz._id.to_s
          unless qzp_arr.empty?
            qzp_arr.each_with_index{|qzp_uid,qzp_index|
              params[:bank_quiz_qizs][index][:bank_qizpoint_qzps][qzp_index][:id] = qzp_uid
            }
          end
        else
          raise SwtkErrors::SavePaperHasError.new(I18.t("papers.messages.save_paper.debug", :message => qiz.errors.messges))
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
    status = Common::Paper::Status::Analyzing
    #return result if params[:infromation].blank?

    paper_h = JSON.parse(self.paper_json)
    paper_h["information"]["paper_status"] = status
    paper_h["bank_quiz_qizs"] = params[:bank_quiz_qizs]

    self.update_attributes({
      :paper_json => paper_h.to_json || "",
      :paper_status => status
    })
  end

  def save_ckp_rollback
    #
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
    
    #update qizpoint ckps json
    qzps = bank_quiz_qizs.map{|qiz| qiz.bank_qizpoint_qzps }.flatten
    qzps.each{|qzp|
      qzp.format_ckps_json
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
    result = {
      Common::CheckpointCkp::Dimesion::Knowledge => [],
      Common::CheckpointCkp::Dimesion::Skill => [],
      Common::CheckpointCkp::Dimesion::Ability => []
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

  # 返回得分点与指标的Mapping数组
  #
  # [return]: Array
  def qzps_checkpoints_mapping ckp_level=1
    result = []
    return result if bank_quiz_qizs.blank?
    qzps = ordered_qzps
    return result if qzps.blank?
    target_level = ckp_level
    target_level = -1 if ckp_level > Common::Report::CheckPoints::DefaultLevelEnd
    pap_checkpoint_model = qzps[0].bank_checkpoint_ckps[0].class
    qzps.each_with_index{|qzp, index|
      qzp.format_ckps_json if qzp.ckps_json.blank?
      ckp_h = JSON.parse(qzp.ckps_json)
      target_level_ckp_h = Common::CheckpointCkp.ckp_types_loop {|dimesion|
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
      result << {
        "qzp_id" => qzp.id.to_s,
        "qzp_order" => (index+1).to_s,
        "qzp_type" => qzp.type,
        "ckps" => target_level_ckp_h
      }
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
        "subject_teacher",
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
        Common::Locale::i18n('quizs.order')
      ]

      # row 4
      # title
      title_row_arr = [
        Common::Locale::i18n('dict.grade'),
        Common::Locale::i18n('dict.classroom'),
        Common::Locale::i18n('dict.head_teacher'),
        Common::Locale::i18n('dict.subject_teacher'),
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
        cells= sheet.rows.last.cells[8..cols_count].map{|cell| {:key=> cell.r, :value=> title_row_arr[cell.index].to_s}}
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

  def format_user_name args=[]
    #args.join("_")
    args.join(Common::Uzer::UserNameSperator)
  end

  def format_user_password_row role,params_h
    row_data = {
      Common::Role::Teacher.to_sym => {
        :username => params_h[:user_name],
        :password => "",
        :name => params_h[:name],
        :report_url => "",
        :op_guide => Common::Locale::i18n('reports.op_guide_details'),
        :tenant_uid => params_h[:tenant_uid]
      },
      Common::Role::Pupil.to_sym => {
        :username => params_h[:user_name],
        :password => "",
        :name => params_h[:name],
        :stu_number => params_h[:stu_number],
        :report_url => "",#Common::SwtkConstants::MyDomain + "/reports/new_square?username=",
        :op_guide => Common::Locale::i18n('reports.op_guide_details'),
        :tenant_uid => params_h[:tenant_uid]
      }
    }

    params_h[:tenant_uid] = (tenant.nil?? "":tenant.uid) if params_h[:tenant_uid].blank?

    ret = User.add_user params_h[:user_name],role, params_h

    target_username = ""
    if (ret.is_a? Array) && ret.empty?
      row_data[role.to_sym][:password] = Common::Locale::i18n("scores.messages.info.old_user")
      row_data[role.to_sym][:report_url] = generate_url
      target_username = ret[0]
    elsif (ret.is_a? Array) && !ret.empty?
      row_data[role.to_sym][:password] = ret[1]
      row_data[role.to_sym][:report_url] = generate_url
      target_username = ret[0]
    else
      row_data[role.to_sym][:password] = Common::Locale::i18n("scores.messages.error.add_user_failed")
    end
    
    associate_user_and_pap role, target_username if (ret.is_a? Array)
    return row_data[role.to_sym].values
  end

  def associate_user_and_pap role, username
    target_user = User.where(name: username).first
    return false unless target_user
    case role
    when "pupil"
      target_pupil = target_user.pupil
      return false unless target_pupil
      pup_uid = target_pupil.uid
      bpp = Mongodb::BankPupPap.new
      bpp.save_pup_pap pup_uid, self._id.to_s
    when "teacher"
      target_teacher = target_user.teacher
      return false unless target_teacher
      tea_uid = target_teacher.uid
      btp = Mongodb::BankTeaPap.new
      btp.save_tea_pap tea_uid, self._id.to_s
    end
    return true
  end

  def generate_url
    return Common::SwtkConstants::MyDomain 
  end

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


end

