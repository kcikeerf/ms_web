# -*- coding: UTF-8 -*-

class Mongodb::BankQuizScore
  include Mongoid::Document
  include Mongoid::Timestamps

#  validates :pap_uid, :qiz_uid, length:{maximum: 36}

  before_save :format_float

  field :loc_uid, type: String
  #
  field :province, type: String
  field :city, type: String
  field :district, type: String
  field :school, type: String
  field :grade, type: String
  field :classroom, type: String
  #   
  field :pup_uid, type: String #pupil id
  field :pap_uid, type: String #paper id
  field :qiz_uid, type: String
  field :order, type: String #quiz order
  field :real_score, type: Float #real score

  has_many :bank_qizpoint_scores, class_name: "Mongodb::BankQizpointScore"

  private
  def format_float
    self.real_score = self.real_score.nil?? 0.0:("%.2f" % self.real_score).to_f
  end

end
