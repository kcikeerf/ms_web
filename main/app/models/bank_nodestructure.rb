class BankNodestructure < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  has_many :bank_tbc_ckps, foreign_key: "tbs_uid"
  has_many :bank_checkpoint_ckps, foreign_key: "node_uid"#, through: :bank_tbc_ckps

  has_many :bank_node_catalogs, foreign_key: "node_uid", dependent: :destroy

  has_many :bank_nodestructure_subject_ckps, foreign_key: 'node_structure_uid', dependent: :destroy
  has_many :bank_subject_checkpoint_ckps, through: :bank_nodestructure_subject_ckps

  accepts_nested_attributes_for :bank_checkpoint_ckps, :bank_node_catalogs, :bank_nodestructure_subject_ckps

  validates :grade, :subject, :version, :volume, presence: true

  scope :by_subject, ->(subject) { where(subject: subject) }

  scope :by_grade, ->(grade) { where(grade: grade) }

  class << self

    def list_structures
      result = {}
      self.all.each{|bn|
        if bn.subject && !result.keys.include?(bn.subject)
          result[bn.subject] = {"label" => I18n.t("dict.#{bn.subject}"),"items" =>{}}
  #      else
  #        return result
        end
        keys_arr = result[bn.subject]["items"].keys
        if bn.grade && !keys_arr.include?(bn.grade)
          result[bn.subject]["items"][bn.grade] = {"label" => I18n.t("dict.#{bn.grade}"), "items" =>{}}
  #      else
  #        return result
        end
        keys_arr = result[bn.subject]["items"][bn.grade]["items"].keys
        if bn.version && bn.volume && !keys_arr.include?(bn.version+"("+bn.volume+")")
          result[bn.subject]["items"][bn.grade]["items"][bn.version+"("+bn.volume+")"] = {"label" => I18n.t("dict.#{bn.version}") + "("+I18n.t("dict.#{bn.volume}")+")", "node_uid" => bn.uid, "items"=>{}}
  #      else
  #        return result
        end
      }
      return result
    end

    def subject_gather
      self.all.map{|item| {label: I18n.t("dict.#{item.subject}"), name: item.subject} }.uniq
    end

    def grade_gather(subject)
      by_subject(subject).map{ |m| {label: I18n.t("dict.#{m.grade}"), name: m.grade} }
    end

    def version_gather(subject, grade)
      by_subject(subject).by_grade(grade).map{ |m| { label: I18n.t('dict.' + m.version), name: m.version } }
    end

    def unit_gather(subject, grade, version)
      by_subject(subject).by_grade(grade).where(version: version).map{ |m| { label: I18n.t('dict.' + m.volume), name: m.volume, node_uid: m.uid } }
    end

  end

  # 判断指标是否使用科目指标体系
  def judge_subject_ckp?
    bank_nodestructure_subject_ckps.size > 0 ? true : false
  end

  def add_ckps(ckps)
    transaction do
      bank_nodestructure_subject_ckps.destroy_all
      ckp_arr = [].tap do |arr|
        ckps.each {|ckp| arr << {subject_ckp_uid: ckp} }
      end
      bank_nodestructure_subject_ckps.create(ckp_arr)
    end
  end

end
