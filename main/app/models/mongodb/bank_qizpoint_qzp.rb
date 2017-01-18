# -*- coding: UTF-8 -*-

class Mongodb::BankQizpointQzp
  include Mongoid::Document
  include Mongodb::MongodbPatch

  before_create :set_create_time_stamp
  before_save :set_update_time_stamp
  before_save :format_score

  # validates :quz_uid,:pap_uid, length: {maximum: 36}
  # validates :tbs_sid,:type, length: {maximum: 50}
  # validates :answer, :desc, length: {maximum: 500}

  field :quz_uid, type: String
  field :pap_uid, type: String
  field :tbs_sid, type: String
  field :type, type: String
  field :answer, type: String
  field :desc, type: String
  field :ckps_json, type: String
  field :score, type: Float
  field :order, type: String
  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  belongs_to :bank_quiz_qiz, class_name: "Mongodb::BankQuizQiz"
  has_and_belongs_to_many :bank_paper_paps, class_name: "Mongodb::BankPaperPap"
  has_many :bank_qizpoint_qzp_histories, class_name: "Mongodb::BankQizpointQzpHistory"

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

    result = {
      Common::CheckpointCkp::Dimesion::Knowledge => [], 
      Common::CheckpointCkp::Dimesion::Skill => [],
      Common::CheckpointCkp::Dimesion::Ability => []
    }

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
        Mongodb::BankPaperPap.ckp_weights_modification({
          :subject => ckp.subject,
          :dimesion=> ckp.dimesion, 
          :weights => ckp.weights, 
          :difficulty=> bank_quiz_qiz.blank?? nil : bank_quiz_qiz.levelword2
        })
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

  def save_qizpoint params
     begin
       self.quz_uid = params[:quz_uid] || ""
       self.pap_uid = params[:pap_uid] || ""
       self.tbs_sid = params[:tbs_sid] || ""
       self.type = params[:type] || ""
       self.answer = params[:answer] || ""
       self.desc = params[:desc] || ""
       self.score = params[:score] || 0.00
       self.order = params[:order] || '0'#).ljust(Common::Paper::Constants::OrderWidth, '0')
       self.save!
     rescue Exception => ex
       return false
     end
     return true
  end

  private
  def format_score
    self.score = self.score.nil?? 0.0:("%.2f" % self.score).to_f
  end
end
