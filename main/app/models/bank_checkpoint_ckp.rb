class BankCheckpointCkp < ActiveRecord::Base
#  include Tenacity
#  include MongoMysqlRelations

  self.primary_key = "uid"

#  to be implemented when the range is clear
#
#  validates :is_entity, 

  include ActiveRecordPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp  

  before_create :init_uid

  has_many :bank_ckp_comments, foreign_key: "ban_uid"
  has_many :bank_tbc_ckps, foreign_key: "ckp_uid3"
  has_many :bank_nodestructures, through: :bank_tbc_ckps

#  t_has_many :bank_ckp_qzps, class_name: "Mongodb::BankCkpQzp", foreign_key: "ckp_uid"
#  t_has_many :bank_qizpoint_qzps, through: :bank_ckp_qzps, class_name: "Mongodb::BankCkpQzp"#, foreign_key: "qzp_uid"
#  from_mysql_has_many :bank_ckp_qzps, :class => "Mongodb::BankCkpQzp", :foreign_key => "ckp_uid"
#  from_mysql_has_many :bank_qizpoint_qzps, :class => Mongodb::BankQizpointQzp, :through => Mongodb::BankCkpQzp

  accepts_nested_attributes_for :bank_ckp_comments,:bank_nodestructures

  # will change in the future
  def self.get_ckps params={}
    result = {"knowledge" => { "label" => I18n.t("dict.knowledge"), "children"=>{}}, 
              "skill"=>{"label"=> I18n.t("dict.skill"), "children" => {}}, 
              "ability" => {"label" => I18n.t("dict.ability"), "children"=>{}}}
    arr = [self.where("LENGTH(rid) = ?", 3), self.where("LENGTH(rid) = ?", 6), self.where("LENGTH(rid) = ?", 9)]
    arr.each{|level|
      level.each{|item|
        current_item = {
          "uid" => item.uid,
          "rid" => item.rid,
          "dimesion" => item.dimesion,
          "checkpoint" => item.checkpoint,
          "is_entity" => item.is_entity || true
        }
        case item.rid.length
        when 3
          result[item.dimesion]["children"][item.rid] = current_item
          result[item.dimesion]["children"][item.rid]["children"] = {}
        when 6
          result[item.dimesion]["children"][item.rid.slice(0,3)]["is_entity"] = false
          result[item.dimesion]["children"][item.rid.slice(0,3)]["children"][item.rid] = current_item
          result[item.dimesion]["children"][item.rid.slice(0,3)]["children"][item.rid]["children"] = {}
        when 9
          result[item.dimesion]["children"][item.rid.slice(0,3)]["children"][item.rid.slice(0,6)]["is_entity"] = false
          result[item.dimesion]["children"][item.rid.slice(0,3)]["children"][item.rid.slice(0,6)]["children"][item.rid] = current_item
        end 
      }
    }
    return result
  end

  def bank_qizpoint_qzps
    result_arr =[]
    qzps = Mongodb::BankCkpQzp.where(ckp_uid: self.uid).to_a
    qzps.each{|qzp|
      result_arr << Mongodb::BankQizpointQzp.where(_id: qzp.qzp_uid).first
    }
    return result_arr
  end

  private
  def init_uid
    self.uid=Time.now.to_snowflake.to_s
  end

end
