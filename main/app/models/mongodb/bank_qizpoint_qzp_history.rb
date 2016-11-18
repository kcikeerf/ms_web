# -*- coding: UTF-8 -*-

class Mongodb::BankQizpointQzpHistory
  include Mongoid::Document
  include Mongoid::Timestamps

#  validates :pap_uid, :qzp_uid, :qiz_his_uid, length:{maximum: 36}

  before_save :format_float

#  field :pap_uid, type: String
#  field :qiz_uid, type: String
#  field :qiz_his_uid, type: String
  field :order, type: Integer # use the record the order in the quiz
  field :score, type: Float

  belongs_to :bank_paper_pap
  belongs_to :bank_quiz_qiz_history
  belongs_to :bank_qizpoint_qzp


  private
  def format_float
    self.score = self.score.nil?? 0.0:("%.2f" % self.score).to_f
  end
end
