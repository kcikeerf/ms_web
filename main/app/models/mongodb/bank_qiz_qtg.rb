# -*- coding: UTF-8 -*-

class Mongodb::BankQizQtg
  include Mongoid::Document

  validates :qtg_sid, length: {maximum: 200}
  validates :qiz_uid, length: {maximum: 36}

  belongs_to :bank_quiz_qiz

#  field :nid, type: Integer
  field :qtg_sid, type: String
  field :qiz_uid, type: String
end
