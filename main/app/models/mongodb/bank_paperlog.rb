# -*- coding: UTF-8 -*-

class Mongodb::BankPaperlog
  include Mongoid::Document

  validates :pap_uid, length: {maximum: 36}

  belongs_to :bank_paper_pap

#  field :nid, type: Integer
  field :pap_uid, type: String
  field :count, type: Integer
end
