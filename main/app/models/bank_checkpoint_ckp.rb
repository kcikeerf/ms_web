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
  has_many :bank_ckp_cats, foreign_key: "ckp_uid"
  has_many :bank_node_catalogs, through: :bank_ckp_cats
#  has_many :bank_tbc_ckps, foreign_key: "ckp_uid3"
#  has_many :bank_nodestructures, through: :bank_tbc_ckps
  belongs_to :bank_nodestructure, foreign_key: "node_uid"

#  t_has_many :bank_ckp_qzps, class_name: "Mongodb::BankCkpQzp", foreign_key: "ckp_uid"
#  t_has_many :bank_qizpoint_qzps, through: :bank_ckp_qzps, class_name: "Mongodb::BankCkpQzp"#, foreign_key: "qzp_uid"
#  from_mysql_has_many :bank_ckp_qzps, :class => "Mongodb::BankCkpQzp", :foreign_key => "ckp_uid"
#  from_mysql_has_many :bank_qizpoint_qzps, :class => Mongodb::BankQizpointQzp, :through => Mongodb::BankCkpQzp

  accepts_nested_attributes_for :bank_ckp_comments

  # will change in the future
  # 
  # node_uid: node structure uid
  #
  def self.get_ckps params={}
    result = {"knowledge" => { "label" => I18n.t("dict.knowledge"), "children"=>{}}, 
              "skill"=>{"label"=> I18n.t("dict.skill"), "children" => {}}, 
              "ability" => {"label" => I18n.t("dict.ability"), "children"=>{}}}
    cond_str = "LENGTH(rid) = ?"
    cond_str += " and node_uid = #{params["node_uid"]}" unless params["node_uid"].blank?
    arr = [self.where(cond_str, 3), self.where(cond_str, 6), self.where(cond_str, 9)]
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

  # 
  # str_pid: parent rid
  # node_uid: node structure uid
  #
  def self.get_child_ckps params
    result = {"pid" => params["str_pid"], "nodes"=>[]}
    return result if params["node_uid"].blank?
    pid = params["str_pid"]
    target_objs = self.where("node_uid = #{params["node_uid"]}") if params["node_uid"]
    result["nodes"] = BankRid.get_child target_objs, pid
    result["nodes"].map!{|item|

      { "uid" => item.uid,
        "rid" => item.rid,
        "dimesion" => item.dimesion,
        "checkpoint" => item.checkpoint,
        "is_entity" => item.is_entity}

    }
    return result
  end

  # 
  # str_pid: parent rid
  # node_uid: node structure uid
  #
  def self.save_ckp params
    return false if params["node_uid"].blank?
    target_objs = self.where("node_uid = #{params["node_uid"]}") if params["node_uid"]
    new_rid = BankRid.get_new_rid target_objs, params["str_pid"]
    new_ckp = self.new({
      "dimesion" => params["dimesion"],
      "rid" => new_rid,
      "checkpoint" => params["checkpoint"],
      "desc" => params["desc"],
      "is_entity" => false})
    new_ckp.save!
    return true
  end

  #
  # str_uid: current check point uid 
  # str_pid: parent rid
  # node_uid: node structure uid
  #
  #
  def self.update_ckp params
    return false if params["str_uid"].blank?
    current_ckp = self.where("uid = ?", params["str_uid"]) if params["str_uid"]
    if params[str_pid]
      ActiveRecord::Base.transaction do
        new_ckp = self.save_ckp params 
        current_ckp.destroy! if new_ckp
      end
    else
      current_ckp
    end
  end

  def self.delete_ckp params

  end

  # 
  # str_pid: parent rid
  # node_uid: node structure uid
  #
  def self.get_ckp_count params
    result = 0
    
    if params[str_pid].blank?
      target_objs = self.where("node_uid = #{params["node_uid"]}") if params["node_uid"]
      result = target_objs.count
    else
      BankRid.get_child target_objs, pid  
    end

    result = target_objs.count if target_objs
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
