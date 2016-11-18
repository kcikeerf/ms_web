# -*- coding: UTF-8 -*-

class Mongodb::BankPapPtg
  include Mongoid::Document

  validates :ptg_sid, length: {maximum: 200}
  validates :pap_uid, length: {maximum: 36}

  belongs_to :bank_paper_pap

#  field :nid, type: Integer
  field :ptg_sid, type: String
  field :pap_uid, type: String
end
