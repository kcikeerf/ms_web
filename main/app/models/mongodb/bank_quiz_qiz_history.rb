# -*- coding: UTF-8 -*-

class Mongodb::BankQuizQizHistory
  include Mongoid::Document
  include Mongoid::Timestamps

#  validates :pap_uid, :qiz_uid, length:{maximum: 36}

  before_save :format_float

#  field :pap_uid, type: String
#  field :qiz_uid, type: String
  
  field :order, type: Integer # use to record the order in the paper
  field :score, type: Float

  belongs_to :bank_paper_pap
  belongs_to :bank_quiz_qiz
  has_many :bank_qizpoint_qzp_histories, class_name: "Mongodb::BankQizpointQzpHistory"

  private
  def format_float
    self.score = self.score.nil?? 0.0:("%.2f" % self.score).to_f
  end
end
