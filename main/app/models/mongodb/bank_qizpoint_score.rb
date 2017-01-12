# -*- coding: UTF-8 -*-

class Mongodb::BankQizpointScore
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

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
  field :test_id, type: String
  field :pup_uid, type: String #pupil id
  field :pap_uid, type: String #paper id
  field :qzp_uid, type: String #qizpoint id
  field :tenant_uid, type: String #tenant id
  field :order, type: String #qizpoint order
  field :real_score, type: Float #real score
  field :full_score, type: Float

  belongs_to :bank_quiz_score, class_name: "Mongodb::BankQuizScore"

  index({_id: 1}, {background: true})
  index({dt_update:-1},{background: true})
  index({test_id: 1, pup_uid: 1}, {background: true})  

  private
  def format_float
    self.real_score = self.real_score.nil?? 0.0:("%.2f" % self.real_score).to_f
  end
end
