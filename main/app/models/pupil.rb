class Pupil < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  scope :by_grade, ->(grade) { where(grade: grade) if grade.present? }
  scope :by_classroom, ->(classroom) { where(classroom: classroom) if classroom.present? }
  scope :by_keyword, ->(keyword) { where("name LIKE ?", "%"+keyword+"%") if keyword.present? }

  belongs_to :location, foreign_key: "loc_uid"

  def papers
    pap_uids = Mongodb::BankPupPap.where(pup_uid: sself.uid).map{|item| item.pap_uid}
    Mongodb::BankPaperPap.where(:_id.in =>pap_uids).order({dt_update: :desc})
  end

  def self.save_info(options)
    options[:sex] = Common::Locale.hanzi2pinyin(options[:sex]) if options.keys.include?("sex")
  	options = options.extract!(:user_id, :name, :loc_uid, :sex, :stu_number, :grade, :classroom)
  	create(options)
  end

  def report_menu pap_uid
    current_paper = Mongodb::BankPaperPap.where(_id: pap_uid).first
    pupil_report = Mongodb::PupilReport.where({:pap_uid => pap_uid, :pup_uid => self.uid}).first
    result = {
      :key => self.stu_number,
      :label => self.name,
      :report_name => current_paper.heading + I18n.t("dict.ce_shi_zhen_duan_bao_gao"),
      :report_subject => (current_paper.subject.nil?? I18n.t("dict.unknown") : I18n.t("dict.#{current_paper.subject}")) + "&middot" + I18n.t("dict.ge_ren_bao_gao"),
      :data_type => "pupil",
      :report_id => pupil_report.nil?? "":pupil_report._id,
      :items => []
     }
  end
end
  