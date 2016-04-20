class Mongodb::BankQuizQiz
  include Mongoid::Document

  include MongodbPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  validates :pap_uid, :tbs_uid, :tpl_id, length:{maximum: 36}
  validates :cat, :type, :levelword2, :levelword, length:{maximum: 50}
  validates :text, length: {maximum: 1000}
  validates :answer, :desc, length: {maximum: 500}
  
  before_save :format_float

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

  private
  def format_float
    self.score = self.score.nil?? 0.0:("%.2f" % self.score).to_f
    self.time = self.time.nil?? 0.0:("%.2f" % self.time).to_f
    self.level = self.level.nil?? 0.0:("%.2f" % self.level).to_f
  end
end
