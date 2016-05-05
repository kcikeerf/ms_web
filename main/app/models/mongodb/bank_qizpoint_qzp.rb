class Mongodb::BankQizpointQzp
  include Mongoid::Document

  validates :quz_uid,:pap_uid, length: {maximum: 36}
  validates :tbs_sid,:type, length: {maximum: 50}
  validates :answer, :desc, length: {maximum: 500}

  before_save :format_score

#  field :uid, type: String
  field :quz_uid, type: String
  field :pap_uid, type: String
  field :tbs_sid, type: String
  field :type, type: String
  field :answer, type: String
  field :desc, type: String
  field :score, type: Float

  has_one :bank_ckp_qzp, class_name: "Mongodb::BankCkpQzp"

  belongs_to :bank_quiz_qiz
  has_and_belongs_to_many :bank_paper_paps, classs_name: "Mongodb::BankPaperPap"
  has_many :bank_qizpoint_qzp_histories, class_name: "Mongodb::BankQizpointQzpHistory"

  def save_qizpoint params
     self.quz_uid = params["quz_uid"].nil?? nil:params["quz_uid"]
     self.pap_uid = params["pap_uid"].nil?? nil:params["pap_uid"]
     self.tbs_sid = params["tbs_sid"].nil?? nil:params["tbs_sid"]
     self.type = params["type"].nil?? nil:params["type"]
     self.answer = params["answer"].nil?? nil:params["answer"]
     self.desc = params["desc"].nil?? nil:params["desc"]
     self.score = params["score"].nil?? nil:params["score"]
     self.save!
     return true
  end

  private
  def format_score
    self.score = self.score.nil?? 0.0:("%.2f" % self.score).to_f
  end
end
