class Location < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  has_many :class_teacher_mappings, foreign_key: "loc_uid"
  has_many :pupils, foreign_key: "loc_uid"

  def teachers
    self.class_teacher_mappings.map{|item| 
      {
        :subject => item.subject, 
        :teacher => Teacher.where(uid:item.tea_uid).first
      }
    }

  end

  def head_teacher
    tea_uid = self.class_teacher_mappings.where(head_teacher: true).first.tea_uid
    return Teacher.where(uid: tea_uid).first
  end

  def subject_teacher subject
    tea_uid = self.class_teacher_mappings.where(subject: subject, head_teacher: false).first.tea_uid
    return Teacher.where(uid: tea_uid).first
  end

  def self.get_school_numbers
    return Location.all.map{|l| l.school_number}.uniq
  end

  def self.generate_school_number
    result = ""
    arr = [*'1'..'9'] + [*'A'..'Z'] + [*'a'..'z']
    Common::School::NumberLength.times{ result << arr.sample}
    return result
  end

  def self.get_report_menus role, pap_uid, loc_h
    current_paper = Mongodb::BankPaperPap.where(_id: pap_uid).first
    report_name, grade_subject, klass_subject, pupil_subject = format_report_title current_paper.heading,current_paper.subject
    result = {}
    case role
    when Common::Role::Analyzer
      grade_report = Mongodb::GradeReport.where(loc_h).first
      result ={ :key => loc_h[:grade],
                :label => I18n.t("dict.nian_ji_bao_gao"),#I18n.t("dict.#{loc_h[:grade]}")+I18n.t("dict.#{page.reports.report}"),
                :report_name => format_report_name(current_paper.heading, I18n.t("dict.nian_ji_bao_gao")),
                :report_subject => grade_subject,
                :pupil_number => 0,
                :report_url => format_grade_report_url_params((grade_report.nil?? "":grade_report._id)),
                :data_type=>"grade",
                :report_id => grade_report.nil?? "":grade_report._id,#format_grade_report_url_params((grade_report.nil?? "":grade_report._id)),
                :items => []}
    when Common::Role::Teacher
      result ={ :key => loc_h[:grade],
                :label => I18n.t("dict.ban_ji_bao_gao"),#I18n.t("dict.#{loc_h[:grade]}")+I18n.t("page.reports.report"),
                :report_name => format_report_name(current_paper.heading, I18n.t("dict.ban_ji_bao_gao")),
                :report_subject => grade_subject,
                :pupil_number => 0,
                :report_url => nil,
                :data_type=> nil,
                :report_id => nil,
                :items => []}
    when Common::Role::Pupil

    end

    if role == Common::Role::Analyzer || Common::Role::Teacher
      klasses = Location.where(loc_h)#.order(classroom: :ASC) #asc
      klasses = klasses.sort{|a,b| Common::Locale.mysort(Common::Locale::KlassMapping[a.classroom],Common::Locale::KlassMapping[b.classroom]) }
      klasses.each{|klass|
         param_h = loc_h.deep_dup
         param_h[:classroom] = klass.classroom
         param_h[:pap_uid] = pap_uid
         klass_report = Mongodb::ClassReport.where(param_h).first
         klass_pupil_number =  klass.pupils.size
         klass_h = {
            :key => klass.classroom,
            :label => I18n.t("dict.#{klass.classroom}")+I18n.t("page.reports.report"),
            :report_name => format_report_name(current_paper.heading, I18n.t("dict.ban_ji_bao_gao")),
            :report_subject => klass_subject,
            :pupil_number => klass_pupil_number, 
            :report_url => klass_report.nil?? "":format_class_report_url_params((klass_report.nil?? "":klass_report._id)),
            :report_id => klass_report.nil?? "":klass_report._id,#klass_report.nil?? "":format_class_report_url_params((klass_report.nil?? "":klass_report._id)),
            :data_type => "klass",
            :items => []
         }
         result[:pupil_number] += klass_pupil_number
         pupils = klass.pupils.sort{|a,b| Common::Locale.mysort a.stu_number,b.stu_number} #asc
         pupils.each{|pupil|
           param_h = {}
           param_h[:pup_uid] = pupil.uid
           param_h[:pap_uid] = pap_uid
           pupil_report = Mongodb::PupilReport.where(param_h).first
           klass_h[:items] << {
             :key => pupil.stu_number,
             :label => pupil.name,
             :report_name => format_report_name(current_paper.heading, I18n.t("dict.ge_ren_bao_gao")),
             :report_subject => pupil_subject,
             :report_url => pupil_report.nil?? "":format_pupil_report_url_params((pupil_report.nil?? "":pupil_report._id)),
             :data_type => "pupil",
             :report_id => pupil_report.nil?? "":pupil_report._id,#pupil_report.nil?? "":format_pupil_report_url_params((pupil_report.nil?? "":pupil_report._id)),
             :items => []
           }
         }
        result[:items] << klass_h
      }
    end
    return result
  end

  def self.format_report_title heading,subject
    report_name = heading + I18n.t("dict.ce_shi_zhen_duan_bao_gao")
    subject_prefix = I18n.t("dict.#{subject}") + "&middot"
    grade_subject = subject_prefix + I18n.t("dict.nian_ji_bao_gao")
    klass_subject = subject_prefix + I18n.t("dict.ban_ji_bao_gao")
    pupil_subject = subject_prefix + I18n.t("dict.ge_ren_bao_gao")
    return report_name,grade_subject,klass_subject,pupil_subject
  end

  def self.format_report_name heading,suffix
    heading + I18n.t("dict.ce_shi_zhen_duan_bao_gao") + "(#{suffix})"
  end

  def self.format_grade_report_url_params report_id
    "/grade_reports/index?type=grade_report&report_id=#{report_id}"
  end

  def self.format_class_report_url_params report_id
#    "/class_reports/index?pap_uid=#{pap_uid}" + loc_h.map{|k,v| "#{k}=#{v}" }.join("&")
    "/class_reports/index?type=class_report&report_id=#{report_id}"
  end

  def self.format_pupil_report_url_params report_id
    "/pupil_reports/index?type=pupil_report&report_id=#{report_id}"
  end
end
