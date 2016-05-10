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
      if bn.subject && !result.keys.include?(bn.subject)
        result[bn.subject] = {"label" => I18n.t("dict.#{bn.subject}"), "items" =>{}}
      end
      keys_arr = result[bn.subject]["items"].keys
      if bn.grade && !keys_arr.include?(bn.grade)
        result[bn.subject]["items"][bn.grade] = {"label" => I18n.t("dict.#{bn.grade}"), "items" =>{}}
      end
      keys_arr = result[bn.subject]["items"][bn.grade]["items"].keys
      if bn.version && bn.volume && !keys_arr.include?(bn.version+"("+bn.volume+")")
        result[bn.subject]["items"][bn.grade]["items"][bn.version+"("+bn.volume+")"] = {"label" => I18n.t("dict.#{bn.version}") + "("+I18n.t("dict.#{bn.volume}")+")", "items"=>{}}
      end
    }
    return result
  end

  private
  def init_uid
    self.uid=Time.now.to_snowflake.to_s
  end
end
