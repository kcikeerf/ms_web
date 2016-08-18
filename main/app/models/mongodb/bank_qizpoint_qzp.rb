class Mongodb::BankQizpointQzp
  include Mongoid::Document
#  include Tenacity
#  include MongoMysqlRelations

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
  field :order, type: String
 
#  has_many :bank_ckp_qzps, class_name: "Mongodb::BankCkpQzp", foreign_key: "qzp_uid"
#  t_has_many :bank_checkpoint_ckps, through: :bank_ckp_qzps, class_name: "Mongodb::BankCkpQzp"#, foreign_key: "ckp_uid" 
#  has_many :bank_ckp_qzps, class_name: "Mongodb::BankCkpQzp", foreign_key: "qzp_uid"
#  to_mysql_has_many :bank_checkpoint_ckps, class_name: "BankCheckpointCkp", through: "Mongodb::BankCkpQzp"

  belongs_to :bank_quiz_qiz, class_name: "Mongodb::BankQuizQiz"
  has_and_belongs_to_many :bank_paper_paps, class_name: "Mongodb::BankPaperPap"
  has_many :bank_qizpoint_qzp_histories, class_name: "Mongodb::BankQizpointQzpHistory"

  def bank_checkpoint_ckps
    result_arr =[]
    ckps = Mongodb::BankCkpQzp.where(qzp_uid: self._id.to_s).to_a
    ckps.each{|ckp|
      result_arr << BankCheckpointCkp.where(uid: ckp.ckp_uid).first
    }
    return result_arr
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
