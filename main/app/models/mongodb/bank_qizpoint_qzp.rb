# -*- coding: UTF-8 -*-

class Mongodb::BankQizpointQzp
  include Mongoid::Document
  include Mongodb::MongodbPatch
  include SwtkLockPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp
  before_save :format_score

  # validates :quz_uid,:pap_uid, length: {maximum: 36}
  # validates :tbs_sid,:type, length: {maximum: 50}
  # validates :answer, :desc, length: {maximum: 500}

  belongs_to :paper_outline, class_name: "Mongodb::PaperOutline"
  belongs_to :bank_quiz_qiz, class_name: "Mongodb::BankQuizQiz"
  has_and_belongs_to_many :bank_paper_paps, class_name: "Mongodb::BankPaperPap"
  has_many :bank_ckp_qzps, class_name: "Mongodb::BankCkpQzp", foreign_key: "qzp_uid", dependent: :delete
  has_many :bank_quiz_tag_links, class_name: "Mongodb::BankQuizTagLink", foreign_key: "qzp_uid", dependent: :delete

  field :quz_uid, type: String
  field :pap_uid, type: String
  field :tbs_sid, type: String
  field :type, type: String
  field :answer, type: String
  field :desc, type: String
  field :ckps_json, type: String
  field :paper_outline_json, type: String
  field :score, type: Float
  field :order, type: String #系统顺序
  field :asc_order, type: Integer #递增顺序
  field :custom_order, type: String #自定义顺序

  #是否为空
  field :is_empty, type: Boolean, default: false

  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  #
  def bank_checkpoint_ckps
    result_arr =[]
    ckps = Mongodb::BankCkpQzp.where(qzp_uid: self._id.to_s).to_a
    ckps.each{|ckp|
      ckp_source = ckp.source_type.blank?? "BankCheckpointCkp":ckp.source_type
      ckp_klass = ckp_source.constantize
      result_arr << ckp_klass.where(uid: ckp.ckp_uid).first
    }
    return result_arr
  end

  #   
  def format_ckps_json
    ckps = bank_checkpoint_ckps
    return {} if ckps.blank?
    checkpoint_system = bank_checkpoint_ckps[0].checkpoint_system
    if checkpoint_system.sys_type == "xy_default"
      result = {
        Common::CheckpointCkp::Dimesion::Knowledge => [], 
        Common::CheckpointCkp::Dimesion::Skill => [],
        Common::CheckpointCkp::Dimesion::Ability => []
      }
    else
      result = {
        "other" => []
      }
    end
    ckps.each{|ckp|
      next unless ckp

      unless ckp.subject
        logger.debug ">>>#{ckp}: no subject information<<<"
      end

      ckp_ancestors = BankRid.get_all_higher_nodes(ckp.families,ckp)
      ckp_ancestors.sort!{|a,b| Common::CheckpointCkp.compare_rid_plus(a.rid, b.rid) }
      ckps_arr = ckp_ancestors.push(ckp)

      ckp_uid_path = "/#{ckps_arr.map(&:uid).join('/')}"
      ckp_rid_path = "/#{ckps_arr.map(&:rid).join('/')}"
      weights_arr = ckps_arr.map{|ckp|
        if checkpoint_system.sys_type == "xy_default"
          Mongodb::BankPaperPap.ckp_weights_modification({
            :subject => ckp.subject,
            :dimesion=> ckp.dimesion, 
            :weights => ckp.weights, 
            :difficulty=> bank_quiz_qiz.blank?? nil : bank_quiz_qiz.levelword2
          })
        else
          ckp.weights.present? ? ckp.weights*Common::CheckpointCkp::DifficultyModifier[:default] : 1
        end
      }
      ckp_weights_path = "/#{weights_arr.join('/')}"
      result[ckp.dimesion] << { 
        ckp_uid_path => {
          "weights" => ckp_weights_path, 
          "rid" => ckp_rid_path
        } 
      }
    }
    update_attributes({ckps_json: result.to_json})
  end

  def lv2_checkpoint
    ckps = bank_checkpoint_ckps
    result = {
      Common::CheckpointCkp::Dimesion::Knowledge => [], 
      Common::CheckpointCkp::Dimesion::Skill => [],
      Common::CheckpointCkp::Dimesion::Ability => []
    }
    ckps.each{|ckp|
      if ckp.present?
        lv2_ckp = ckp.lv2_ckp
        if lv2_ckp.present?
          result[ckp.dimesion] << {
            uid: lv2_ckp.uid,
            checkpoint: lv2_ckp.checkpoint,
            rid: lv2_ckp.rid
          }
        end
      end
    }
    return result
  end

  def end_checkpoint
    ckps = bank_checkpoint_ckps
    result = {
      Common::CheckpointCkp::Dimesion::Knowledge => [], 
      Common::CheckpointCkp::Dimesion::Skill => [],
      Common::CheckpointCkp::Dimesion::Ability => []
    }
    ckps.each{|ckp|
      if ckp.present?
        result[ckp.dimesion] << {
          uid: ckp.uid,
          checkpoint: ckp.checkpoint,
          rid: ckp.rid
        }
      end
    }
    return result
  end

  def level1_levle2_info
    ckps = bank_checkpoint_ckps
    result = {
      Common::CheckpointCkp::Dimesion::Knowledge => [], 
      Common::CheckpointCkp::Dimesion::Skill => [],
      Common::CheckpointCkp::Dimesion::Ability => []
    }
    ckps.each {|ckp|
      lv2_ckp = ckp.lv2_ckp
      lv1_ckp = lv2_ckp.parent
      result[ckp.dimesion] << "#{lv1_ckp.checkpoint}/#{lv2_ckp.checkpoint}"
    }
    return result
  end

  def level1_levle2_info_plus
    result = {
      Common::CheckpointCkp::Dimesion::Knowledge => [], 
      Common::CheckpointCkp::Dimesion::Skill => [],
      Common::CheckpointCkp::Dimesion::Ability => []
    }
    ckpJson = JSON.parse(self.ckps_json)
    ckpJson.each {|key,value|
      # Rails.logger.info '---------'
      # Rails.logger.info key
      # Rails.logger.info value
      # Rails.logger.info '-----------'
      if value.present?
        ckp_uid_str_arr =  value[0].keys 
        if ckp_uid_str_arr.present?
          ckp_uid_str_arr.each {|tt| 
            ckp_uid_arr = tt.split("/").delete_if {|item| item == ""}
            dimesion_ckps = []
            ckp_uid_arr.each {|ckp_uid|
              ckp = BankSubjectCheckpointCkp.where(uid: ckp_uid).first
              if ckp.present?
                dimesion_ckps.push(ckp)
              end
            }
            result[key] << {
              uid: dimesion_ckps.map(&:uid).join("/"),
              rid: dimesion_ckps.map(&:rid).join("/"),
              name: dimesion_ckps.map(&:checkpoint).join("/")
            }
          }
        end
      end
    }
    result
  end

  def format_paper_outline_json
    return {} if paper_outline.blank?
    outline_arr = [ paper_outline.ancestors, paper_outline ].flatten.compact!
    outline_ids = "/#{outline_arr.map{|item| item.id.to_s}.join('/')}"
    outline_rid = "/#{outline_arr.map{|item| item.rid.to_s}.join('/')}"
    update_attributes(paper_outline_json: {
      "ids" => outline_ids,
      "rids" => outline_rid
    }.to_json)
  end

  def save_qizpoint params
     begin
        self.quz_uid = params["quz_uid"] || ""
        self.pap_uid = params["pap_uid"] || ""
        self.tbs_sid = params["tbs_sid"] || ""
        self.type = params["type"] || ""
        self.answer = params["answer"] || ""
        self.desc = params["desc"] || ""
        self.score = params["score"] || 0.00
        self.order = params["order"] || '0'#).ljust(Common::Paper::Constants::OrderWidth, '0')
        self.custom_order = params["custom_order"] || ""
        self.paper_outline_id = params["paper_outline_id"] || nil 
        self.save!
        if params["qzp_tags"]
          save_qzp_tags params["qzp_tags"]
        end
     rescue Exception => ex
       return false
     end
     return true
  end

  def save_qzp_tags tags_str
    bank_quiz_tag_links.destroy_all
    tag_arr = tags_str.split("|")
    tag_arr.each { |str|
      tag = Mongodb::BankTag.where(content: str).first
      unless tag
        tag = Mongodb::BankTag.new(content: str)
        tag.save
      end
      Mongodb::BankQuizTagLink.new.save_ins nil, self._id.to_s, tag._id.to_s
    }
  end


  def point_info
    bank_quiz_qiz = self.bank_quiz_qiz
    result = {}
    result[:uid] = self._id.to_s
    result[:text] = bank_quiz_qiz.text
    result[:answer] = self.answer
    result[:cat_cn] = Common::Locale::i18n("dict.#{bank_quiz_qiz.cat}")
    result[:levelword] = Common::Locale::i18n("dict.#{bank_quiz_qiz.levelword2}")
    result[:order] = self.order
    result[:custom_order] = self.custom_order.present? ? self.custom_order : nil
    result[:asc_order] = self.asc_order.present? ? self.asc_order : nil
    result[:score] = self.score
    return result
  end

  def bank_tag_ids
    bank_quiz_tag_links.map(&:tag_uid)
  end

  def bank_tags
    Mongodb::BankTag.where({id: {"$in" => bank_tag_ids }})
  end

  private
  def format_score
    # self.score = self.score.nil?? 0.0:("%.2f" % self.score).to_f
  end
end