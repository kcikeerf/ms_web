class Pupil < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  scope :by_grade, ->(grade) { where(grade: grade) if grade.present? }
  scope :by_classroom, ->(classroom) { where(classroom: classroom) if classroom.present? }
  scope :by_keyword, ->(keyword) { where("name LIKE ?", "%"+keyword+"%") if keyword.present? }

  belongs_to :location, foreign_key: "loc_uid"
  belongs_to :user, foreign_key: "user_id"

  ########类方法定义：begin#######
  class << self
    def get_list params
      params[:page] = params[:page].blank?? Common::SwtkConstants::DefaultPage : params[:page]
      params[:rows] = params[:rows].blank?? Common::SwtkConstants::DefaultRows : params[:rows]
      conditions = []
      conditions << self.send(:sanitize_sql, ["pupils.name LIKE ?", "%#{params[:name]}%"]) unless params[:name].blank?
      conditions << self.send(:sanitize_sql, ["pupils.classroom LIKE ?", "%#{Common::Locale.hanzi2pinyin(params[:classroom])}%"]) unless params[:classroom].blank?
      conditions << self.send(:sanitize_sql, ["pupils.grade LIKE ?", "%#{params[:subject]}%"]) unless params[:subject].blank?
      conditions << self.send(:sanitize_sql, ["users.name LIKE ?", "%#{params[:user_name]}%"]) unless params[:user_name].blank? 
      conditions << self.send(:sanitize_sql, ["tenants.name_cn LIKE ?", "%#{params[:tenant_name]}%"]) unless params[:tenant_name].blank? 
      conditions = conditions.any? ? conditions.collect { |c| "(#{c})" }.join(' AND ') : nil
      result = self.joins(:user, location: :tenant).where(conditions).order("dt_update desc").page(params[:page]).per(params[:rows])      
      result.each_with_index{|item, index|
        area_h = {
          :province_rid => "",
          :city_rid => "",
          :district_rid => ""
        }
        tenant = item.location.nil?? nil : item.location.tenant
        area_h = tenant.area_pcd if tenant
        h = {
          :tenant_uids =>  tenant.nil?? "":tenant.uid,
          :tenant_name => tenant.nil?? "":tenant.name_cn,
          :user_name => item.user.nil?? "":item.user.name,
          :qq => item.user.nil?? "":(item.user.qq.blank?? "":item.user.qq),
          :phone => item.user.nil?? "":(item.user.phone.blank?? "":item.user.phone),
          :email => item.user.nil?? "":(item.user.email.blank?? "":item.user.email)
        }
        h.merge!(area_h)
        h.merge!(item.attributes)
        h["sex_label"] = Common::Locale::i18n("dict.#{h["sex"]}")
        h["grade_label"] = Common::Locale::i18n("dict.#{h["grade"]}")
        h["classroom_label"] = Common::Klass::klass_label h["classroom"]
        h["dt_update"]=h["dt_update"].strftime("%Y-%m-%d %H:%M")
        result[index] = h
      }
      return result
    end

    def save_info(options)
      # options[:sex] = Common::Locale.hanzi2pinyin(options[:sex]) if options.keys.include?("sex")
      options = options.extract!(:user_id, :name, :loc_uid, :sex, :stu_number, :grade, :classroom, :tenant_uid)
      create(options)
    end

  end
  ########类方法定义：end#######

  def papers
    pap_uids = Mongodb::BankPupPap.where(pup_uid: self.uid).map{|item| item.pap_uid}
    Mongodb::BankPaperPap.where(:_id.in =>pap_uids).order({dt_update: :desc})
  end



  def save_obj params
    paramsh = {
      :user_id => params[:user_id],
      :stu_number => params[:stu_number],
      :sex => params[:sex],
      :name => params[:name], 
      :grade => params[:grade],
      :classroom => params[:classroom],
      :tenant_uid => params[:tenant_uids]
    }
    update_attributes(paramsh)
    save!
  end

  def destroy_pupil
    transaction do
      self.user.destroy! if self.user
      self.destroy! if self
    end
  end

  def report_menu pap_uid
    current_paper = Mongodb::BankPaperPap.where(_id: pap_uid).first
    pupil_report = Mongodb::PupilReport.where({:pap_uid => pap_uid, :pup_uid => self.uid}).first
    result = {
      :key => self.stu_number,
      :label => self.name,
      :report_name => current_paper.heading + Common::Locale::i18n("dict.ce_shi_zhen_duan_bao_gao"),
      :report_subject => (current_paper.subject.nil?? Common::Locale::i18n("dict.unknown") : Common::Locale::i18n("dict.#{current_paper.subject}")) + "&middot" + Common::Locale::i18n("dict.ge_ren_bao_gao"),
      :data_type => "pupil",
      :report_id => pupil_report.nil?? "":pupil_report._id,
      :items => []
     }
  end
end
  