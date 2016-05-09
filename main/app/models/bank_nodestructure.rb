class BankNodestructure < ActiveRecord::Base
  self.primary_key = "uid"

  include ActiveRecordPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  before_create :init_uid

  has_many :bank_tbc_ckps, foreign_key: "tbs_uid"
  has_many :bank_checkpoint_ckps, through: :bank_tbc_ckps

  accepts_nested_attributes_for :bank_checkpoint_ckps

  def self.list_structures
    result = {}
    self.all.each{|bn|
      if bn.subject && !result.keys.include?(I18n.t("dict.#{bn.subject}"))
        result[I18n.t("dict.#{bn.subject}")] = {}
      end
      if bn.grade && !result[I18n.t("dict.#{bn.subject}")].keys.include?(I18n.t("dict.#{bn.grade}"))
        result[I18n.t("dict.#{bn.subject}")][I18n.t("dict.#{bn.grade}")] = {}
      end
      if bn.version && bn.volume && 
         !result[I18n.t("dict.#{bn.subject}")][I18n.t("dict.#{bn.grade}")].keys.include?(I18n.t("dict.#{bn.version}")+"("+I18n.t("dict.#{bn.volume}")+")")
        result[I18n.t("dict.#{bn.subject}")][I18n.t("dict.#{bn.grade}")][I18n.t("dict.#{bn.version}")+"("+I18n.t("dict.#{bn.volume}")+")"] = {}
      end
    }
    return result
  end

  private
  def init_uid
    self.uid=Time.now.to_snowflake.to_s
  end
end
