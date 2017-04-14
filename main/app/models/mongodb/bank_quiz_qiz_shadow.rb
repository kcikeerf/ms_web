class Mongodb::BankQuizQizShadow
  include Mongoid::Document

  belongs_to :bank_quiz_qiz, class_name: "Mongodb::BankQuizQiz"
  belongs_to :bank_paper_pap_shadow, class_name: "Mongodb::BankPaperPapShadow"
  
  has_many :bank_qizpoint_qzp_shadows, class_name: "Mongodb::BankQizpointQzpShadow"
end
