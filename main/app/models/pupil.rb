class Pupil < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  belongs_to :location, foreign_key: "loc_uid"

  def self.save_info(options)
    options[:sex] = Common::Locale.hanzi2pinyin(options[:sex]) if options.keys.include?("sex")
  	options = options.extract!(:user_id, :name, :loc_uid, :sex, :stu_number)
  	create(options)
  end

  def report_menu pap_uid
    current_paper = Mongodb::BankPaperPap.where(_id: pap_uid).first
    pupil_report = Mongodb::PupilReport.where({:pap_uid => pap_uid, :pup_uid => self.uid}).first
    result = {
      :key => self.stu_number,
      :label => self.name,
      :report_name => current_paper.heading + I18n.t("dict.ce_shi_zhen_duan_bao_gao"),
      :report_subject => I18n.t("dict.#{current_paper.subject}") + "&middot" + I18n.t("dict.ge_ren_bao_gao"),
      :data_type => "pupil",
      :report_id => pupil_report.nil?? "":pupil_report._id,
      :items => []
     }
  end
end
  