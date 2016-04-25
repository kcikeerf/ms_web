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

  belongs_to :bank_paper_pap  

  def save_quiz params
    params = JSON.parse(params["_json"]) if params["_json"]
    p params.class
    self.update_attributes({
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
      p bqq, index
      self.bank_qizpoint_qzps.build({
        :quz_uid => bqq["quz_uid"].nil?? nil:bqq["quz_uid"],
        :pap_uid => bqq["pap_uid"].nil?? nil:bqq["pap_uid"],
        :tbs_sid => bqq["tbs_sid"].nil?? nil:bqq["tbs_sid"],
        :type => bqq["type"].nil?? nil:bqq["type"],
        :answer => bqq["answer"].nil?? nil:bqq["answer"],
        :desc => bqq["desc"].nil?? nil:bqq["desc"],
        :score => bqq["score"].nil?? nil:bqq["score"]
      }).save!
      p self.bank_qizpoint_qzps[index]
      self.bank_qizpoint_qzps[index].bank_ckp_qzp = Mongodb::BankCkpQzp.new({
        :ckp_uid => bqq["bank_ckp_qzp"]["ckp_uid"].nil?? nil:bqq["bank_ckp_qzp"]["ckp_uid"],
        :qzp_uid => bqq["bank_ckp_qzp"]["qzp_uid"].nil?? nil:bqq["bank_ckp_qzp"]["qzp_uid"], 
        :weights => bqq["bank_ckp_qzp"]["weights"].nil?? nil:bqq["bank_ckp_qzp"]["weights"]  
      })
    }
      
    return true
  end

  private
  def format_float
    self.score = self.score.nil?? 0.0:("%.2f" % self.score).to_f
    self.time = self.time.nil?? 0.0:("%.2f" % self.time).to_f
    self.level = self.level.nil?? 0.0:("%.2f" % self.level).to_f
  end
end
