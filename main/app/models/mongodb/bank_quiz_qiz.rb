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
  field :node_uid, type: String
  field :pap_uid, type: String
  field :tbs_uid, type: String
  field :tpl_id, type: String
  field :ext1, type: Integer
  field :ext2, type: Integer
  field :cat, type: String
  field :type, type: String
  field :text, type: String
  field :answer, type: String
  field :desc, type: String
  field :score, type: Float
  field :time, type: Float
  field :levelword2, type: String
  field :level, type: Float
  field :levelword, type: String
  field :levelorder, type: Integer
  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  has_many :bank_quizlogs,  class_name: "Mongodb::BankQuizlog"
  has_many :bank_qiz_qtgs,  class_name: "Mongodb::BankQizQtg"
  has_many :bank_qizpoint_qzps, class_name: "Mongodb::BankQizpointQzp"
  has_many :bank_quiz_qiz_histories, class_name: "Mongodb::BankQuizQizHistory"

  has_and_belongs_to_many :bank_paper_paps, class_name: "Mongodb::BankPaperPap" 

  def save_quiz params
    #params = JSON.parse(params["_json"]) if params["_json"]
    result = false
   
    begin
      original_qzp_ids = self.bank_qizpoint_qzps.map{|qzp| qzp._id.to_s}
      delete_all_related_qizpoints original_qzp_ids
#      self.bank_qizpoint_qzps=[]
      self.update_attributes({
        :node_uid => params["node_uid"].nil?? nil:params["node_uid"],
        :pap_uid => params["pap_uid"].nil?? nil:params["pap_uid"],
        :tbs_uid => params["tbs_uid"].nil?? nil:params["tbs_uid"],
        :tpl_id => params["tpl_id"].nil?? nil:params["tpl_id"],
        :ext1 => params["ext1"].nil?? nil:params["ext1"],
        :ext2 => params["ext2"].nil?? nil:params["ext2"],
        :cat => params["cat"].nil?? nil:params["cat"],
        :type => params["type"].nil?? nil:params["type"],
        :text => params["text"].nil?? nil:params["text"],
        :answer => params["answer"].nil?? nil:params["answer"],
        :desc => params["desc"].nil?? nil:params["desc"],
        :score => params["score"].nil?? nil:params["score"],
        :time => params["time"].nil?? nil:params["time"],
        :levelword2 => params["levelword2"].nil?? nil:params["levelword2"],
        :level => params["level"].nil?? nil:params["level"],
        :levelword => params["levelword"].nil?? nil:params["levelword"],
        :levelorder => params["levelorder"].nil?? nil:params["levelorder"]
      })
      self.save!

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

      }
    
    rescue Exception => ex
      return false
    end
    return result
  end

  def destroy_quiz
    begin
      delete_all_related_qizpoints self.bank_qizpoint_qzps.map{|qzp| qzp._id.to_s}
#      self.bank_qizpoint_qzps = []
      self.destroy
    rescue Exception => ex
      p ex.message
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
        "type_label" => I18n.t("dict.#{qzp.type}"),
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
    self.score = self.score.nil?? 0.0:("%.2f" % self.score).to_f
    self.time = self.time.nil?? 0.0:("%.2f" % self.time).to_f
    self.level = self.level.nil?? 0.0:("%.2f" % self.level).to_f
  end
end
