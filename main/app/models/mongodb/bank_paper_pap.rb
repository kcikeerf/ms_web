# -*- coding: UTF-8 -*-

class Mongodb::BankPaperPap

  attr_accessor :current_user_id

  include Mongoid::Document

  include Mongodb::MongodbPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

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
  field :analyze_json, type: String
  field :paper_status, type: String

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  index({province: 1, city: 1, district:1}, {background: true})
  index({_id: 1}, {background: true})
  index({user_id: 1}, {background: true})
  index({grade: 1}, {background: true})
  index({subject: 1}, {background: true})
  index({paper_status: 1}, {background: true})
  index({dt_update:-1},{background: true})

  has_many :bank_paperlogs, class_name: "Mongodb::BankPaperlog"
  has_many :bank_pap_ptgs, class_name: "Mongodb::BankPapPtg"
  has_and_belongs_to_many :bank_quiz_qizs, class_name: "Mongodb::BankQuizQiz"
  has_many :bank_quiz_qiz_histories, class_name: "Mongodb::BankQuizQizHistory"
  has_and_belongs_to_many :bank_qizpoint_qzps, class_name: "Mongodb::BankQizpointQzp"
  has_many :bank_qizpoint_qzp_histories, class_name: "Mongodb::BankQizpointQzpHistory"
  has_many :bank_pap_cats, class_name: "Mongodb::BankPapCat", dependent: :delete 
  has_many :bank_paper_pap_pointers, class_name: "Mongodb::BankPaperPapPointer", dependent: :delete

  # class method
  class << self
    def ckp_weights_modification args={}
      if !args[:dimesion].blank? && !args[:weights].blank? && !args[:difficulty].blank?
        result = args[:weights]*Common::CheckpointCkp::DifficultyModifier[args[:dimesion].to_sym][args[:difficulty].to_sym]
      elsif !args[:weights].blank?
        result = args[:weights]*Common::CheckpointCkp::DifficultyModifier[:default]
      else
        result = 1
      end
    end
  end

  def save_pap params
    status = Common::Paper::Status::None
    if params[:information][:heading] && params[:bank_quiz_qizs].blank?
      status = Common::Paper::Status::New
    elsif params[:information][:heading] && params[:bank_quiz_qizs] && self.bank_quiz_qizs.blank?
      status = Common::Paper::Status::Editting    
    else
      # do nothing
    end

    #area_Uid, area_rid = Area.get_area_uid_rid params[:informtion]
    #tenant_uid= Tenant.get_tenant_uid params[:information]
    #target_area = Area.get_area params[:information]
    target_current = Common::Uzer.get_tenant current_user_id
 
    #json保存前的处理
    params[:paper] = ""
    if target_current
      params[:information][:province] = target_current.area_pcd[:province_name_cn]
      params[:information][:city] = target_current.area_pcd[:city_name_cn]
      params[:information][:district] = target_current.area_pcd[:district_name_cn]
      params[:information][:school] = target_current.name_cn
    end
    #
    target_area = Area.get_area params[:information]

    self.update_attributes({
      :user_id => current_user_id || "",
      :area_uid => target_area.nil?? "" : target_area.uid,
      :tenant_uid => target_current.nil?? "" : target_current.uid,
      :heading => params[:information][:heading] || "",
      :subheading => params[:information][:subheading] || "",
      :orig_file_id => params[:orig_file_id] || "",
      :paper_json => params.to_json || "",
      :paper_html => params[:paper_html] || "",
      :answer_html => params[:answer_html] || "",
      :paper_status => status
    })
    unless self.errors.messages.empty?
      raise SwtkErrors::SavePaperHasError.new(I18.t("papers.messages.save_paper.debug", :message => self.errors.messages)) 
    end
  end

  def submit_pap params
    params = params.deep_dup
    #result = true
    #begin

      #return result if params[:infromation].blank?
    self.update_attributes({
      :order => params[:order] || "",
      :heading => params[:information][:heading] || "",
      :subheading => params[:information][:subheading] || "",
      :province => tenant.area_pcd[:province_name_cn],#params[:information][:province] || "",
      :city => tenant.area_pcd[:city_name_cn],#params[:information][:city] || "",
      :district => tenant.area_pcd[:district_name_cn], #params[:information][:district] || "",
      :school => tenant.name_cn, #params[:information][:school] || "",
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

    #rescue Exception => ex
    #  result = false
    #end
   
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
    #rescue Exception => ex
    #  result = false
    #  self.update_attributes({:paper_status => Common::Paper::Status::Editting})
    #end

    # save all quiz
    #begin
    if params[:bank_quiz_qizs]
      params[:bank_quiz_qizs].each_with_index{|quiz,index|
        # store quiz
        qzp_arr = []
        qiz = Mongodb::BankQuizQiz.new
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
        #
        # not sure to be implemented
        #
        #store quiz history
        #qiz_hist = Mongodb::BankQuizQizHistory.new(order: quiz.order, score:quiz.score)
        #qiz.bank_quiz_qiz_history = qiz_hist
        #self.bank_quiz_qizs.push(qiz)
      }
    end
    #rescue Exception => ex
    #  result = false
    #  self.update_attributes({:paper_status => Common::Paper::Status::Editting})
    #end
    #return result
    self.update_attributes({
      :paper_status => Common::Paper::Status::Editted,
      :paper_json => params.to_json || ""
    })
  end

  def save_ckp params
    result = true

    begin
      status = Common::Paper::Status::Analyzing
      #return result if params[:infromation].blank?

      paper_h = JSON.parse(self.paper_json)
      paper_h["bank_quiz_qizs"] = params[:bank_quiz_qizs]

      self.update_attributes({
        :paper_json => paper_h.to_json || "",
        :paper_status => status
      })
    rescue Exception => ex
      result=false
    end
    return result
  end

  def submit_ckp params
    result = true

    begin
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
          #result = Mongodb::BankQuizQiz.save_all_qzps current_qiz, param
        }
      end

      paper_h = JSON.parse(self.paper_json)
      paper_h["bank_quiz_qizs"] = params[:bank_quiz_qizs]

      self.update_attributes({
        :paper_json => paper_h.to_json || "",
        :paper_status => status
      })
    rescue Exception => ex
      result=false
      self.update_attributes({:paper_status => ex.message})# Common::Paper::Status::Analyzing})
    end
    return result
  end

  def bank_node_catalogs
    cat_uids = self.bank_pap_cats.map{|cat| cat.uid }
    cat_uids.map{|uid|
      BankNodeCatalog.where(uid: uid) 
    }
  end

  #
  # used for report
  # checkpoints and qizpoints mapping
  #
  def get_pap_ckps_qzp_mapping
    result = {
      :knowledge => {:level1=>{}, :level2=>{}},
      :skill => {:level1=>{}, :level2=>{}},
      :ability => {:level1=>{}, :level2=>{}}
    }
    qzpoints = self.bank_quiz_qizs.map{|a| a.bank_qizpoint_qzps}.flatten
    qzpoints.each{|qzp|
      qzp.bank_checkpoint_ckps.each{|ckp|
        next unless ckp
        levels = [*1..Common::Report::CheckPoints::Levels]
        levels.each{|lv|
          # search current level checkpoint
          if ckp.is_a? BankCheckpointCkp
            lv_ckp = BankCheckpointCkp.where("node_uid = '#{self.node_uid}' and rid = '#{ckp.rid.slice(0, Common::SwtkConstants::CkpStep*lv)}'").first
          elsif ckp.is_a? BankSubjectCheckpointCkp
            xue_duan = BankNodestructure.get_subject_category(self.grade)
            lv_ckp = BankSubjectCheckpointCkp.where("category = '#{xue_duan}' and rid = '#{ckp.rid.slice(0, Common::SwtkConstants::CkpStep*lv)}'").first
          end
          temp_arr = result[ckp.dimesion.to_sym]["level#{lv}".to_sym][lv_ckp.checkpoint.to_sym] || []
          result[ckp.dimesion.to_sym]["level#{lv}".to_sym][lv_ckp.checkpoint.to_sym] = temp_arr
          result[ckp.dimesion.to_sym]["level#{lv}".to_sym][lv_ckp.checkpoint.to_sym] << { 
            :ckp_uid => ckp.uid,
            :weights => ckp.weights,
            :qzp_uid => qzp._id.to_s
          }
        }
      }
    }
    return result
  end

  #
  # 
  #
  # def get_pap_ckp_ancestors
  #   result = {
  #     :knowledge => {},
  #     :skill => {},
  #     :ability => {}
  #   }
  #   qzpoints = self.bank_quiz_qizs.map{|a| a.bank_qizpoint_qzps}.flatten
  #   qzpoints.each{|qzp|
  #     qzp.bank_checkpoint_ckps.each{|ckp|
  #       next unless ckp
  #       # search current level checkpoint
  #       lv1_ckp = BankCheckpointCkp.where("node_uid = '#{self.node_uid}' and rid = '#{ckp.rid.slice(0, 3)}'").first
  #       lv2_ckp = BankCheckpointCkp.where("node_uid = '#{self.node_uid}' and rid = '#{ckp.rid.slice(0, 6)}'").first

  #       result[ckp.dimesion.to_sym]

  #       lv1_temph = result[ckp.dimesion.to_sym][lv1_ckp.checkpoint.to_sym] || {}
  #       result[ckp.dimesion.to_sym][lv1_ckp.checkpoint.to_sym] = lv1_temph
  #       result[ckp.dimesion.to_sym][lv1_ckp.checkpoint.to_sym][lv2_ckp.checkpoint.to_sym] = {}

  #     }
  #   }
  #   return result
  # end

  #
  # used for report
  # get dimesion total score and each checkpoint total score
  #
  def get_dimesion_ckp_total_score ckps_qzps
    total_score = {
      :knowledge => 0, 
      :skill => 0, 
      :ability => 0
    }

    ckp_total_score = {
       :knowledge => {:level1 =>{}, :level2=>{}},
       :skill => {:level1 =>{}, :level2=>{}},
       :ability => {:level1 =>{}, :level2=>{}}
    }

    ckps_qzps.each{|dimesion_key, dimesions|
      dimesions.each{|level_key, levels|
        levels.each{|lv_ckp, values|
          ckp_total_score[dimesion_key.to_sym][level_key.to_sym][lv_ckp.to_sym] = 0
          values.each{|value|
            qzp = Mongodb::BankQizpointQzp.where(_id: value[:qzp_uid]).first
            if qzp
              total_score[dimesion_key.to_sym] += qzp.score*value[:weights]
              ckp_total_score[dimesion_key.to_sym][level_key.to_sym][lv_ckp.to_sym] += qzp.score*value[:weights]
            end
          }
        }
      }
    }
    return total_score, ckp_total_score
  end

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

    wb.add_worksheet(:name => I18n.t('scores.excel.score_title')) do |sheet|
      sheet.sheet_protection.password = 'forbidden_by_k12ke'

      # row 1
      # location input field
      location_row_arr = [
        I18n.t('dict.province'),
        tenant.area_pcd[:province_name_cn],
        I18n.t('dict.city'),
        tenant.area_pcd[:city_name_cn],
        I18n.t('dict.district'),
        tenant.area_pcd[:district_name_cn],
        I18n.t('dict.tenant'),
        tenant.name_cn
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
        tenant.uid # 隐藏tenant uid在表格中, version1.0，没什么用先埋下
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
        I18n.t('quizs.order')
      ]

      # row 4
      # title
      title_row_arr = [
        I18n.t('dict.grade'),
        I18n.t('dict.classroom'),
        I18n.t('dict.head_teacher'),
        I18n.t('dict.subject_teacher'),
        I18n.t('dict.name'),
        I18n.t('dict.pupil_number'),
        I18n.t('dict.sex'),
        "#{I18n.t('quizs.full_score')}(#{self.score})"
      ]

      # row 4
      # every qizpoint score  
      score_row_arr = title_row_arr.deep_dup
      score_row_arr.pop()
      score_row_arr.push(self.score)

      quizs = self.bank_quiz_qizs.sort{|a,b| Common::Paper::quiz_order(a.order,b.order) }
      qiz_order = 0
      quizs.each{|qiz|
        qzps = qiz.bank_qizpoint_qzps.sort{|a,b| Common::Paper::quiz_order(a.order,b.order) }
        #全部从1开始升序排知识点，旧排序注释（1/2）
        qzp_count = qzps.size
        qzps.each_with_index{|qzp, qzp_index|
          hidden_title_row_arr.push(qzp._id)
          #全部从1开始升序排知识点，旧排序注释（2/2）
          #(qzp_count > 1) ? order_row_arr.push(qzp.order.sub(/0*$/, '')) : order_row_arr.push(qiz.order)
          qiz_order += 1
          #(qzp_count > 1) ? order_row_arr.push(qzp.order.sub(/0*$/, '') + "-#{qiz_order}") : order_row_arr.push(qiz.order + "-#{qiz_order}")
          order_row_arr.push(qiz_order)
          title_row_arr.push(qzp.score)
        }
      }

      #sheet.add_row location_row_arr, :style => [title_cell, title_cell, title_cell,unlocked,title_cell,unlocked,title_cell,unlocked]
      sheet.add_row location_row_arr, :style => [title_cell, info_cell, title_cell,info_cell,title_cell,info_cell,title_cell,info_cell]
      # sheet.add_data_validation("B1",{
      #   :type => :list,
      #   :formula1 => "areaList!A1:#{province_cell.r}",
      #   :showDropDown => false,
      #   :showInputMessage => true,
      #   :promptTitle => I18n.t('dict.province'),
      #   :prompt => ""
      # })
      # sheet.add_data_validation("D1",{
      #   :type => :list,
      #   :formula1 => "areaList!A2:#{city_cell.r}",
      #   :showDropDown => false,
      #   :showInputMessage => true,
      #   :promptTitle => I18n.t('dict.city'),
      #   :prompt => ""
      # })
      # sheet.add_data_validation("F1",{
      #   :type => :list,
      #   :formula1 => "areaList!A3:#{district_last.cells[0].r}",
      #   :showDropDown => false,
      #   :showInputMessage => true,
      #   :promptTitle => I18n.t('dict.district'),
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
          :formula1 => "gradeList!A1:A#{grade_number}",
          :showDropDown => false,
          :showInputMessage => true,
          :promptTitle => I18n.t('dict.grade'),
          :prompt => ""
        })
        sheet.add_data_validation("B#{line+5}",{
          :type => :list,
          :formula1 => "classroomList!A1:A#{classroom_number}",
          :showDropDown => false,
          :showInputMessage => true,
          :promptTitle => I18n.t('dict.classroom'),
          :prompt => ""
        })
        sheet.add_data_validation("G#{line+5}",{
          :type => :list,
          :formula1 => "sexList!A1:A3",
          :showDropDown => false,
          :showInputMessage => true,
          :promptTitle => I18n.t('dict.sex'),
          :prompt => ""
        })
        cells= sheet.rows.last.cells[8..cols_count].map{|cell| {:key=> cell.r, :value=> title_row_arr[cell.index].to_s}}
        cells.each{|cell|
          sheet.add_data_validation(cell[:key],{
            :type => :whole, 
            :operator => :between, 
            :formula1 => '0', 
            :formula2 => cell[:value], 
            :showErrorMessage => true, 
            :errorTitle => I18n.t("scores.messages.error.wrong_input"), 
            :error => I18n.t("scores.messages.info.correct_score", :min => 0, :max =>cell[:value]), 
            :errorStyle => :information, 
            :showInputMessage => true, 
            :promptTitle => I18n.t("scores.messages.warn.score"), 
            :prompt => I18n.t("scores.messages.info.correct_score", :min => 0, :max =>cell[:value])
          })
        }
        #sheet.rows.last.cells[0..7].each{|col| col.style = info_cell }
        #sheet.rows.last.cells[8..cols_count].each{|col| col.style = data_cell }
      }

    end

    file_path = Rails.root.to_s + "/tmp/#{self._id.to_s}_empty.xlsx"
    out_excel.serialize(file_path)

    score_file = Common::Score.create_empty_score file_path

    self.update(score_file_id: score_file.id)
    File.delete(file_path)
  end

#   # analyze filled score file
#   def analyze_filled_score_file file
#     # score file with scores filled
#     filled_file = Roo::Excelx.new(file.filled_file.current_path)
#     #
#     # test
#     #filled_file = Roo::Excelx.new("/Users/freekick/Workspace/Qidian/swtk/main/uploads/score_upload/5/empty_score.xlsx")
     
#     # read score sheet
#     sheet = filled_file.sheet(I18n.t('scores.excel.score_title')) if filled_file

#     # read title
#     loc_row = sheet.row(1)
#     hidden_row = sheet.row(2)
#     order_row = sheet.row(3)
#     title_row = sheet.row(4)

#     # initial data
#     data_start_row = 5
#     data_start_col = 8
#     total_row = sheet.count
#     total_cols = hidden_row.size

#     loc_h = {
#       :province => Common::Locale.hanzi2pinyin(loc_row[1]),
#       :city => Common::Locale.hanzi2pinyin(loc_row[3]),
#       :district => Common::Locale.hanzi2pinyin(loc_row[5]),
#       :school => Common::Locale.hanzi2pinyin(loc_row[7]),
#       :tenant_uid => tenant.uid
# #      :school_number => Location.generate_school_number
#     }
#     subject = self.subject

#     #excel for user password
#     out_excel = Axlsx::Package.new
#     wb = out_excel.workbook
#     teacher_sheet = wb.add_worksheet(:name => I18n.t('scores.excel.teacher_password_title'))
#     pupil_sheet = wb.add_worksheet(:name => I18n.t('scores.excel.pupil_password_title'))

#     teacher_sheet.sheet_protection.password = 'forbidden_by_qidian'
#     pupil_sheet.sheet_protection.password = 'forbidden_by_qidian'

#     teacher_title_row = [
#         I18n.t('activerecord.attributes.user.name'),
#         I18n.t('activerecord.attributes.user.password'),
#         I18n.t('dict.name'),
#         I18n.t('reports.generic_url')
#     ]
#     teacher_sheet.add_row teacher_title_row

#     pupil_title_row = [
#         I18n.t('activerecord.attributes.user.name'),
#         I18n.t('activerecord.attributes.user.password'),
#         I18n.t('dict.name'),
#         I18n.t('dict.pupil_number'),
#         I18n.t('reports.generic_url')
#     ]
#     pupil_sheet.add_row pupil_title_row

#     #
#     teacher_username_in_sheet = []
#     pupil_username_in_sheet = []
#     #######start to analyze#######      
#     (data_start_row..total_row).each{|index|
#       row = sheet.row(index)
#       grade_pinyin = Common::Locale.hanzi2pinyin(row[0])
#       cells = {
#         :grade => grade_pinyin,
#         :xue_duan => BankNodestructure.get_subject_category(grade_pinyin),
#         :classroom => Common::Locale.hanzi2pinyin(row[1]),
#         :head_teacher => row[2],
#         :teacher => row[3],
#         :pupil_name => row[4],
#         :stu_number => row[5],
#         :sex => row[6]
#       }

#       #
#       # get location
#       #
#       loc_h[:grade] = cells[:grade]
#       loc_h[:classroom] = cells[:classroom]
#       loc = Location.where(loc_h).first
#       if loc.nil?
#         ## 
#         # parameters: province, city, district, school
#         #

#         ###
#         # 因为tenant要预先注册，此处不需要创建学校
#         #
#         # school_numbers = Location.get_school_numbers
#         # new_school_number = Location.generate_school_number
#         # count = 1
#         # while school_numbers.include?(new_school_number)
#         #   new_school_number = Location.generate_school_number
#         #   break if count > 100 # avoid infinite loop
#         #   count+=1
#         # end

#         #loc_h[:school_number] = new_school_number
#         ###

#         loc = Location.new(loc_h)
#         loc.save!
#       end
       
#       user_row_arr = []
#       # 
#       # create teacher user 
#       #
#       head_tea_h = {
#         :loc_uid => loc.uid,
#         :name => cells[:head_teacher],
#         :subject => self.subject,
#         :head_teacher => true,
#         :user_name => format_user_name([tenant.number,Common::Subject::Abbrev[self.subject.to_sym],Common::Locale.hanzi2abbrev(cells[:head_teacher])])
#       }
#       user_row_arr =format_user_password_row(Common::Role::Teacher, head_tea_h)
#       unless teacher_username_in_sheet.include?(user_row_arr[0])
#         teacher_sheet.add_row user_row_arr
#         teacher_username_in_sheet << user_row_arr[0]
#       end
      
#       tea_h = {
#         :loc_uid => loc.uid,
#         :name => cells[:teacher],
#         :subject => self.subject,
#         :head_teacher => false,
#         :user_name => format_user_name([tenant.number,Common::Subject::Abbrev[self.subject.to_sym],Common::Locale.hanzi2abbrev(cells[:teacher])])
#       }
#       user_row_arr = format_user_password_row(Common::Role::Teacher, tea_h)
#       unless teacher_username_in_sheet.include?(user_row_arr[0])
#         teacher_sheet.add_row user_row_arr
#         teacher_username_in_sheet << user_row_arr[0]
#       end

#       #
#       # create pupil user
#       #
#       pup_h = {
#         :loc_uid => loc.uid,
#         :name => cells[:pupil_name],
#         :stu_number => cells[:stu_number],
#         :grade => cells[:grade],
#         :classroom => cells[:classroom],
#         :subject => self.subject,
#         :sex => Common::Locale.hanzi2pinyin(cells[:sex]),
#         :user_name => format_user_name([tenant.number,cells[:stu_number],Common::Locale.hanzi2abbrev(cells[:pupil_name])])
#       }
#       user_row_arr = format_user_password_row(Common::Role::Pupil, pup_h)
#       unless pupil_username_in_sheet.include?(user_row_arr[0])
#         pupil_sheet.add_row user_row_arr
#         pupil_username_in_sheet << user_row_arr[0]
#       end

#       current_user = User.where(name: pup_h[:user_name]).first
#       current_pupil = current_user.nil?? nil : current_user.pupil

#       (data_start_col..(total_cols-1)).each{|qzp_index|
#         param_h = {
#           :province => loc_h[:province],
#           :city => loc_h[:city],
#           :district => loc_h[:district],
#           :school => loc_h[:school],
#           :grade => cells[:grade],
#           :classroom => cells[:classroom],         
#           :pup_uid => current_pupil.nil?? "":current_pupil.uid,
#           :pap_uid => self._id.to_s,
#           :qzp_uid => hidden_row[qzp_index],
#           :tenant_uid => tenant.uid,
#           :order => order_row[qzp_index],
#           :real_score => row[qzp_index],
#           :full_score => title_row[qzp_index]
#         }

#         qizpoint = Mongodb::BankQizpointQzp.where(_id: hidden_row[qzp_index]).first
#         qizpoint_qiz = qizpoint.nil?? nil : qizpoint.bank_quiz_qiz 
#         #next unless qizpoint
#         ckps = qizpoint.bank_checkpoint_ckps
#         ckps.each{|ckp|
#           next unless ckp
#           if ckp.is_a? BankCheckpointCkp
#             lv1_ckp = BankCheckpointCkp.where("node_uid = '#{self.node_uid}' and rid = '#{ckp.rid.slice(0,3)}'").first
#             lv2_ckp = BankCheckpointCkp.where("node_uid = '#{self.node_uid}' and rid = '#{ckp.rid.slice(0,6)}'").first
#           elsif ckp.is_a? BankSubjectCheckpointCkp
#             lv1_ckp = BankSubjectCheckpointCkp.where("category = '#{cells[:xue_duan]}' and rid = '#{ckp.rid.slice(0,3)}'").first
#             lv2_ckp = BankSubjectCheckpointCkp.where("category = '#{cells[:xue_duan]}' and rid = '#{ckp.rid.slice(0,6)}'").first
#           end
#           param_h[:dimesion] = ckp.dimesion
#           param_h[:lv1_uid] = lv1_ckp.uid
#           param_h[:lv1_ckp] = lv1_ckp.checkpoint
#           param_h[:lv1_order] = lv1_ckp.sort
#           param_h[:lv2_uid] = lv2_ckp.uid
#           param_h[:lv2_ckp] = lv2_ckp.checkpoint
#           param_h[:lv2_order] = lv2_ckp.sort
#           param_h[:lv3_uid] = ckp.uid
#           param_h[:lv3_ckp] = ckp.checkpoint
#           param_h[:lv3_order] = ckp.sort
#           param_h[:lv_end_uid] = ckp.uid
#           param_h[:lv_end_ckp] = ckp.checkpoint
#           param_h[:lv_end_order] = ckp.sort
#           #调整权重系数
#           # 1.单题难度关联
#           #
#           param_h[:weights] = self.class.ckp_weights_modification({:dimesion=> param_h[:dimesion], :weights => ckp.weights, :difficulty=> qizpoint_qiz.levelword2})
#           qizpoint_score = Mongodb::BankQizpointScore.new(param_h)
#           qizpoint_score.save!
#         }
#       }
#     }

#     # create user password file
#     file_path = Rails.root.to_s + "/tmp/#{self._id.to_s}_password.xlsx"
#     out_excel.serialize(file_path)
#     file_h = {:score_file_id => self.score_file_id, :file_path => file_path}
#     score_file = Common::Score.create_usr_pwd file_h
#     #File.delete(file_path)
#     #######finish analyze#######  
#   end

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
        :op_guide => I18n.t('reports.op_guide_details')
        # :tenant_uid => tenant.uid
      },
      Common::Role::Pupil.to_sym => {
        :username => params_h[:user_name],
        :password => "",
        :name => params_h[:name],
        :stu_number => params_h[:stu_number],
        :report_url => Common::SwtkConstants::MyDomain + "/reports/new_square?username=",
        :op_guide => I18n.t('reports.op_guide_details')
        # :tenant_uid => tenant.uid
      }
    }

    params_h[:tenant_uid] = tenant.nil?? "":tenant.uid

    ret = User.add_user params_h[:user_name],role, params_h
    target_username = ""
    if (ret.is_a? Array) && ret.empty?
      row_data[role.to_sym][:password] = I18n.t("scores.messages.info.old_user")
      row_data[role.to_sym][:report_url] = generate_url
      target_username = ret[0]
    elsif (ret.is_a? Array) && !ret.empty?
      row_data[role.to_sym][:password] = ret[1]
      row_data[role.to_sym][:report_url] = generate_url
      target_username = ret[0]
    else
      row_data[role.to_sym][:password] = generate_url
    end
    associate_user_and_pap role, target_username
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
=begin   
    result = ""
    #目前只需要试卷的ID信息
    params_h = {
      :pap_uid => self._id.to_s
    } 
    new_rum = ReportUrlMapping.new({:params_json => params_h.to_json })
    new_rum.save
    result = Common::SwtkConstants::MyDomain + "/reports/check/#{new_rum.nil?? "":new_rum.codes}"
    return result
=end
  end

  # def paper_name(type, is_heading=true)
  #   is_heading = false if type == 'usr_pwd_file'
  #   (is_heading ? (heading + '_') : '') + I18n.t("papers.name.#{type}")
  # end

  def download_file_name type
    case type
    when 'usr_pwd_file'
      year_str = quiz_date.strftime('%Y') + I18n.t('dict.nian')
      grade_str = Common::Grade::List[grade.to_sym]
      subject_str = Common::Subject::List[subject.to_sym]
      result = year_str + grade_str + subject_str + I18n.t('reports.check') + "_"
    else
      result = heading + '_'
    end
    result += I18n.t("papers.name.#{type}")
    result
  end

  def is_completed?
    paper_status == Common::Paper::Status::ReportCompleted
  end

  def self.region(papers)
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
      # region_data.select{|r| city << {name: r["_id"]["city"], label: I18n.t('area.' + r["_id"]["city"]), area: [*r["value"]["district"]].uniq.map{|m| {name: m, label: I18n.t('area.' + m)} }} if r["_id"]["province"] == province }
      # region << {name: province, label: I18n.t('area.' + province), city: city}
      region_data.select{ |r| city << {name: r["_id"]["city"], label: r["_id"]["city"], area: Array(r["value"]["district"]).uniq.map{|m| {name: m, label: m} }} if r["_id"]["province"] == province }
      region << {name: province, label: province, city: city}
   
    end
    region
  end

  def self.get_column_arr filter, col_str

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

  def self.get_paper_status_count filter
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

  #######
  #等到bank_paper_pap_pointers弄完，移植走
  def grade_reports
    Mongodb::GradeReport.where(:pap_uid => _id.to_s).to_a
  end

  def class_reports
    Mongodb::ClassReport.where(:pap_uid => _id.to_s).to_a
  end

  def pupil_reports
    Mongodb::PupilReport.where(:pap_uid => _id.to_s).to_a
  end
  ########

  #################################Mobile#####################################

  # 任意检索一个试卷
  # 参数：
  #   grade: 年级
  #   term: 学期
  #   subject: 学科
  #
  def self.get_a_paper params_h
    self.where(params_h).sample
  end

end

