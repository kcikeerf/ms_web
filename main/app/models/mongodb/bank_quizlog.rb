# -*- coding: UTF-8 -*-

class Mongodb::BankQuizlog
  include Mongoid::Document

  validates :qiz_uid, length: {maximum: 36}

  belongs_to :bank_quiz_qiz

#  field :nid, type: Integer
  field :qiz_uid, type: String
  field :count, type: Integer
end
