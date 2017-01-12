# -*- coding: UTF-8 -*-

class Mongodb::BankPaperPapPointer
  include Mongoid::Document

  belongs_to :bank_paper_pap, class_name: "Mongodb::BankPaperPap"
end
