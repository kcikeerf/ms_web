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
  belongs_to :bank_paper_pap

  private
  def format_score
    self.score = self.score.nil?? 0.0:("%.2f" % self.score).to_f
  end
end
