# -*- coding: UTF-8 -*-

class Mongodb::PaperOutline
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :bank_paper_pap, class_name: "Mongodb::BankPaperPap"

  field :name, type: String
  field :rid, type: String
  field :order, type: String
  field :level, type: String
  field :is_end_point, type: String

end
