# -*- coding: UTF-8 -*-

class Mongodb::BankQuizQiz
  include Mongoid::Document

  include Mongodb::MongodbPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp
=begin
  validates :pap_uid, :tbs_uid, :tpl_id, length:{maximum: 36}
  validates :cat, :type, :levelword2, :levelword, length:{maximum: 50}
  validates :text, length: {maximum: 1000}
  validates :answer, :desc, length: {maximum: 500}

  before_save :format_float
=end

  #field :uid, type: String
  field :subject, type: String
  field :node_uid, type: String
  field :pap_uid, type: String
  field :tbs_uid, type: String
  field :tpl_id, type: String
  field :ext1, type: Integer
  field :ext2, type: Integer
  field :cat, type: String
  field :type, type: String
  field :optional, type: Boolean
  field :text, type: String
  field :answer, type: String
  field :desc, type: String
  field :score, type: Float
  field :time, type: Float
  field :levelword2, type: String
  field :level, type: Float
  field :levelword, type: String
  field :levelorder, type: Integer
  field :order, type: String
  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  has_many :bank_quizlogs,  class_name: "Mongodb::BankQuizlog"
  has_many :bank_qiz_qtgs,  class_name: "Mongodb::BankQizQtg"
  has_many :bank_qizpoint_qzps, class_name: "Mongodb::BankQizpointQzp", dependent: :delete 
  has_many :bank_quiz_qiz_histories, class_name: "Mongodb::BankQuizQizHistory"

  has_and_belongs_to_many :bank_paper_paps, class_name: "Mongodb::BankPaperPap" 

  def save_quiz params, paper_status=nil
    #params = JSON.parse(params["_json"]) if params["_json"]
    qzp_arr = []
   
#    begin
      original_qzp_ids = self.bank_qizpoint_qzps.map{|qzp| qzp._id.to_s}
      delete_all_related_qizpoints original_qzp_ids
#      self.bank_qizpoint_qzps=[]
      self.update_attributes({
        :subject => params["subject"] || "",
        :node_uid => params["node_uid"] || "",
        :pap_uid => params["pap_uid"] || "",
        :tbs_uid => params["tbs_uid"] || "",
        :tpl_id => params["tpl_id"] || "",
        :ext1 => params["ext1"] || 0,
        :ext2 => params["ext2"] || 0,
        :cat => params["cat"] || "",
        :type => params["type"] || "",
        :optional => params["optional"] || "",
        :text => params["text"] || "",
        :answer => params["answer"] || "",
        :desc => params["desc"] || "",
        :score => params["score"] || 0.00,
        :time => params["time"] || 0.00,
        :levelword2 => params["levelword2"] || "",
        :level => params["level"] || 0.00,
        :levelword => params["levelword"] || "",
        :levelorder => params["levelorder"] || "",
#        :order => (params["order"].to_s || '0').ljust(Common::Paper::Constants::OrderWidth, '0')
        :order => params["order"] || "0"
      })
      self.save!
=begin
      params["bank_qizpoint_qzps"].each_with_index{|bqq, index|
        qiz_point = Mongodb::BankQizpointQzp.new
        qiz_point.save_qizpoint bqq
        self.bank_qizpoint_qzps.push(qiz_point)
        if bqq["bank_checkpoint_ckps"]
          bqq["bank_checkpoint_ckps"].each{|bcc|
            ckp = Mongodb::BankCkpQzp.new
	    ckp.save_ckp_qzp qiz_point._id, bcc["uid"]
            #self.bank_qizpoint_qzps[index].bank_ckp_qzp = ckp
	  }
        end

      } unless params["bank_qizpoint_qzps"].blank?
=end
      if params["bank_qizpoint_qzps"]
        qzp_arr = save_all_qzps self,params, paper_status
      end
#    rescue Exception => ex
#      return false
#    end
  end

  def save_all_qzps quiz, params, status
    result = []
    params["bank_qizpoint_qzps"].each_with_index{|bqq, index|
      qiz_point = Mongodb::BankQizpointQzp.new
      qiz_point.save_qizpoint bqq
      result << qiz_point._id.to_s
      quiz.bank_qizpoint_qzps.push(qiz_point)
      unless bqq["bank_checkpoints_ckps"].blank?
        if status == Common::Paper::Status::Common::Paper::Status::Analyzing
          save_qzp_all_ckps qiz_point,bqq#["bank_checkpoints_ckps"]
        end
      end
    }
    return result
  end

  def save_qzp_all_ckps qiz_point, params
    params["bank_checkpoints_ckps"].each{|bcc|
      ckp = Mongodb::BankCkpQzp.new
      ckp.save_ckp_qzp qiz_point._id.to_s, bcc["uid"], bcc["ckp_source"]
    }


  end

  def destroy_quiz
    begin
      delete_all_related_qizpoints self.bank_qizpoint_qzps.map{|qzp| qzp._id.to_s}
#      self.bank_qizpoint_qzps = []
      self.destroy
    rescue Exception => ex
      logger.debug(ex.message)
      logger.debug(ex.backtrace)
      return false
    end
    return true
  end

  #
  # get quiz all details 
  #
  def quiz_detail
    result ={}
    qzps = self.bank_qizpoint_qzps
    node = BankNodestructure.where(:uid => self.node_uid).first
    result[:subject] = node.subject
    result[:grade]= node.grade
    result[:version] = node.version + "("+ node.volume + ")"
    result[:text] = self.text
    result[:node_uid] = node.uid
    result[:answer] = self.answer
    result[:desc] =self.desc
    result[:levelword2]=self.levelword2
    result[:bank_qizpoint_qzps] = qzps.map{|qzp|
      { 
        "type" => qzp.type,
        "type_label" => Common::Locale::i18n("dict.#{qzp.type}"),
        "answer" => qzp.answer,
        "desc" => qzp.desc,
        "score" => qzp.score,
        "bank_checkpoint_ckps" => qzp.bank_checkpoint_ckps.map{|bcc|
           {
             "dimesion" => bcc.dimesion,
             "rid" => bcc.rid,
             "uid" => bcc.uid,
             "checkpoint" => bcc.checkpoint,
             "desc" => bcc.desc
           }
        }
      }
    } 
    result
  end


  private 

  def delete_all_related_qizpoints ids
    ids.each{|id|
      qzp = Mongodb::BankQizpointQzp.where(:_id => id)
      ckp_qzps = Mongodb::BankCkpQzp.where(:qzp_uid => id)
      ckp_qzps.each{|ckp_qzp|
        ckp_qzp.destroy_ckp_qzp
      }
      qzp.destroy
    }
  end

  def format_float
    # self.score = self.score.nil?? 0.0:("%.2f" % self.score).to_f
    self.time = self.time.nil?? 0.0:("%.2f" % self.time).to_f
    self.level = self.level.nil?? 0.0:("%.2f" % self.level).to_f
  end
  
end
