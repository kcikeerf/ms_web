# -*- coding: UTF-8 -*-

class Location < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  belongs_to :tenant, foreign_key: "tenant_uid"
  has_many :class_teacher_mappings, foreign_key: "loc_uid", dependent: :destroy
  # has_many :teachers, foreign_key: "tea_uid"
  has_many :pupils, foreign_key: "loc_uid"

  scope :by_tenant, ->(id) { where(tenant_uid: id) }
  scope :by_area, ->(rid) { where("rid LIKE '#{rid}%'") }
  scope :by_grade, ->(str) { where(grade: str) }

  ########类方法定义：begin#######
  class << self
    def get_school_numbers
      return Location.all.map{|l| l.school_number}.uniq
    end

    def generate_school_number
      result = ""
      arr = [*'1'..'9'] + [*'A'..'Z'] + [*'a'..'z']
      Common::Tenant::NumberLength.times{ result << arr.sample}
      return result
    end

    def get_report_menus role, pap_uid, loc_h, options={}
      current_paper = Mongodb::BankPaperPap.where(_id: pap_uid).first
      report_name, grade_subject, klass_subject, pupil_subject = format_report_title current_paper.heading,current_paper.subject
      result = {}
      case role
      when Common::Role::Analyzer,Common::Role::Teacher
        param_h = {:pap_uid => pap_uid }
        grade_report = Mongodb::GradeReport.where(param_h.merge(loc_h)).first
        result ={ :key => loc_h[:grade],
                  :label => Common::Locale::i18n("dict.nian_ji_bao_gao"),#Common::Locale::i18n("dict.#{loc_h[:grade]}")+Common::Locale::i18n("dict.#{page.reports.report}"),
                  :report_name => format_report_name(current_paper.heading, Common::Locale::i18n("dict.nian_ji_bao_gao")),
                  :report_subject => grade_subject,
                  :pupil_number => 0,
                  :report_url => format_grade_report_url_params((grade_report.nil?? "":grade_report._id)),
                  :data_type=>"grade",
                  :report_id => grade_report.nil?? "":grade_report._id,#format_grade_report_url_params((grade_report.nil?? "":grade_report._id)),
                  :items => []}
      # when Common::Role::Teacher
      #   result ={ :key => loc_h[:grade],
      #             :label => Common::Locale::i18n("dict.ban_ji_bao_gao"),#Common::Locale::i18n("dict.#{loc_h[:grade]}")+Common::Locale::i18n("page.reports.report"),
      #             :report_name => format_report_name(current_paper.heading, Common::Locale::i18n("dict.ban_ji_bao_gao")),
      #             :report_subject => grade_subject,
      #             :pupil_number => 0,
      #             :report_url => nil,
      #             :data_type=> nil,
      #             :report_id => nil,
      #             :items => []}
      when Common::Role::Pupil
        result ={ :key => loc_h[:grade],
                  :label => "",#Common::Locale::i18n("dict.#{loc_h[:grade]}")+Common::Locale::i18n("page.reports.report"),
                  :report_name => format_report_name(current_paper.heading, Common::Locale::i18n("dict.ban_ji_bao_gao")),
                  :report_subject => grade_subject,
                  :pupil_number => 0,
                  :report_url => nil,
                  :data_type=> nil,
                  :report_id => nil,
                  :items => []}
      end

      if role == Common::Role::Analyzer || Common::Role::Teacher || Common::Role::Pupil 
        klasses = Location.where(loc_h)#.order(classroom: :ASC) #asc
        klasses = klasses.sort{|a,b| Common::Locale.mysort(Common::Klass::Order[a.classroom],Common::Klass::Order[b.classroom]) }
        klasses.each{|klass|
           param_h = loc_h.deep_dup
           param_h[:classroom] = klass.classroom
           param_h[:pap_uid] = pap_uid
           klass_report = Mongodb::ClassReport.where(param_h).first
           next unless klass_report
           klass_pupil_number =  klass.pupils.size
           klass_label = Common::Klass::List.keys.include?(klass.classroom.to_sym) ? Common::Locale::i18n("dict.#{klass.classroom}") : klass.classroom
           klass_h = {
              :key => klass.classroom,
              :label => klass_label + Common::Locale::i18n("page.reports.report"),
              :report_name => format_report_name(current_paper.heading, Common::Locale::i18n("dict.ban_ji_bao_gao")),
              :report_subject => klass_subject,
              :pupil_number => 0,
              :report_url => nil,
              :data_type=> nil,
              :report_id => nil,
              :items => []
           }
           if options.empty? || !options.keys.include?(:pup_uid)
             klass_h[:pupil_number] = klass_pupil_number
             klass_h[:report_url] = klass_report.nil?? "":format_class_report_url_params((klass_report.nil?? "":klass_report._id))
             klass_h[:report_id] = klass_report.nil?? "":klass_report._id
             klass_h[:data_type] = "klass"
           end
           result[:pupil_number] += klass_pupil_number
           pupils = klass.pupils.sort{|a,b| Common::Locale.mysort a.stu_number,b.stu_number} #asc
           pupils.each{|pupil|
             next if !options.empty? && options[:pup_uid] != pupil.uid
             param_h = {}
             param_h[:pup_uid] = pupil.uid
             param_h[:pap_uid] = pap_uid
             pupil_report = Mongodb::PupilReport.where(param_h).first
             next unless pupil_report
             klass_h[:items] << {
               :key => pupil.stu_number,
               :label => pupil.name,
               :report_name => format_report_name(current_paper.heading, Common::Locale::i18n("dict.ge_ren_bao_gao")),
               :report_subject => pupil_subject,
               :report_url => pupil_report.nil?? "":format_pupil_report_url_params((pupil_report.nil?? "":pupil_report._id)),
               :data_type => "pupil",
               :report_id => pupil_report.nil?? "":pupil_report._id,#pupil_report.nil?? "":format_pupil_report_url_params((pupil_report.nil?? "":pupil_report._id)),
               :items => []
             } #有报告的学生才会出现
           }
          result[:items] << klass_h unless klass_h[:items].blank?
        }
      end
      return result
    end

    def format_report_title heading,subject
      report_name = heading + Common::Locale::i18n("dict.ce_shi_zhen_duan_bao_gao")
      subject_prefix = Common::Locale::i18n("dict.#{subject}") + "&middot"
      grade_subject = subject_prefix + Common::Locale::i18n("dict.nian_ji_bao_gao")
      klass_subject = subject_prefix + Common::Locale::i18n("dict.ban_ji_bao_gao")
      pupil_subject = subject_prefix + Common::Locale::i18n("dict.ge_ren_bao_gao")
      return report_name,grade_subject,klass_subject,pupil_subject
    end

    def format_report_name heading,suffix
      heading + Common::Locale::i18n("dict.ce_shi_zhen_duan_bao_gao") + "(#{suffix})"
    end

    def format_grade_report_url_params report_id
      "/grade_reports/index?type=grade_report&report_id=#{report_id}"
    end

    def format_class_report_url_params report_id
  #    "/class_reports/index?pap_uid=#{pap_uid}" + loc_h.map{|k,v| "#{k}=#{v}" }.join("&")
      "/class_reports/index?type=class_report&report_id=#{report_id}"
    end

    def format_pupil_report_url_params report_id
      "/pupil_reports/index?type=pupil_report&report_id=#{report_id}"
    end
  end
  ########类方法定义：end#######

  def teachers
    self.class_teacher_mappings.map{|item| 
      {
        :subject => item.subject, 
        :teacher => Teacher.where(uid:item.tea_uid).first
      }
    }

  end

  def head_teacher
    objs = self.class_teacher_mappings.where(head_teacher: true).to_a
    result = get_a_teacher objs
    return result
  end

  def subject_teacher subject
    objs = self.class_teacher_mappings.where(subject: subject, head_teacher: false).to_a
    result = get_a_teacher objs
    #若学科老师未找到，则班主任为学科老师 
    result = head_teacher unless result
    return result
  end

  def klass_pupils options={}

  end

  def bank_tests
    _test_ids = Mongodb::BankTestLocationLink.where(loc_uid: self.uid).distinct(:bank_test_id)
    Mongodb::BankTest.where(id: {"$in" => _test_ids })    
  end

  def union_tests
    _test_ids = Mongodb::UnionTestLocationLink.where(loc_uid: self.uid).distinct(:union_test_id)
    Mongodb::UnionTest.where(id: {"$in" => _test_ids })
  end

  ########私有方法: begin#######
  private

    def get_a_teacher objs
      result = nil
      objs.compact!
      return result if objs.blank?
      objs.each{|obj|
        result = Teacher.where(uid: obj.tea_uid).first
        return result if result
      }
      return result
    end 
end
