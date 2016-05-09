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
        result[bn.subject] = {}
      end
      if bn.grade && !result[bn.subject].keys.include?(bn.grade)
        result[bn.subject][bn.grade] = {}
      end
      if bn.version && bn.volume && 
         !result[bn.subject][bn.grade].keys.include?(bn.version+"("+bn.volume+")")
        result[bn.subject][bn.grade][bn.version+"("+bn.volume+")"] = {}
      end
    }
    return result
  end

  private
  def init_uid
    self.uid=Time.now.to_snowflake.to_s
  end
end
