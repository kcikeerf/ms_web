class Mongodb::BankPaperPap
  include Mongoid::Document

  include Mongodb::MongodbPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  validates :caption, :region, :school,:chapter,length: {maximum: 200}
  validates :subject, :type, :version,:grade, :purpose, :levelword, length: {maximum: 50}

#  field :uid, type: String
  field :caption, type: String
  field :region, type: String
  field :school, type: String
  field :subject, type: String
  field :type, type: String
  field :version, type: String
  field :grade, type: String
  field :chapter, type: String
  field :purpose, type: String
  field :year, type: Integer
  field :levelword, type: String
  field :dt_add, type: DateTime
  field :dt_update, type: DateTime

  has_many :bank_paperlogs, class_name: "Mongodb::BankPaperlog"
  has_many :bank_pap_ptgs, class_name: "Mongodb::BankPapPtg"
  has_many :bank_quiz_qizs, class_name: "Mongodb::BankQuizQiz"
  has_many :bank_qizpoint_qzps, class_name: "Mongodb::BankQizpointQzp"
end
