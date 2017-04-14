# -*- coding: UTF-8 -*-

class Mongodb::BankPaperPapShadow
  include Mongoid::Document

  belongs_to :bank_paper_pap, class_name: "Mongodb::BankPaperPap"

  has_many :bank_quiz_qiz_shadows, class_name: "Mongodb::BankQuizQizShadow"
end
