class Teacher < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  has_many :class_teacher_mappings, foreign_key: "tea_uid"

  has_many :classrooms, through: :class_teacher_mappings, foreign_key: 'tea_id'

  accepts_nested_attributes_for :class_teacher_mappings


  def locations
    self.class_teacher_mappings.map{|item| Location.where(uid: item.loc_uid).first}
  end

  def subjects
    self.class_teacher_mappings.map{|item| item.subject }
  end


  def is_class_headteacher?(loc_uid)
    ctm = ClassTeacherMapping.where(loc_uid: loc_uid, tea_uid: uid).first
    ctm.try(:head_teacher)
  end

  def grade
    class_teacher_mappings.first.location.grade
  end

  def pupils
    loc_uids = locations.map{|loc| loc.id}
    Pupil.where(:loc_uid => loc_uids)
  end

  def papers
    pap_uids = Mongodb::BankTeaPap.where(tea_uid: self.uid).map{|item| item.pap_uid}
    Mongodb::BankPaperPap.where(:_id.in =>pap_uids).order({dt_update: :desc})
  end

  def self.save_info(options)
    options = options.extract!(:user_id, :name, :loc_uid, :head_teacher, :subject)
    mapping_hash = {}
    mapping_hash[:loc_uid] = options[:loc_uid]
    mapping_hash[:head_teacher] = options.delete(:head_teacher)
    mapping_hash[:subject] = options[:subject]
    options[:class_teacher_mappings_attributes] = [mapping_hash]
    create(options)
  end


end
