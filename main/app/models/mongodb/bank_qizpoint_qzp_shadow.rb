class Mongodb::BankQizpointQzpShadow
  include Mongoid::Document

  belongs_to :bank_qizpoint_qzp, class_name: "Mongodb::BankQizpointQzp"
  belongs_to :bank_quiz_qiz_shadow, class_name: "Mongodb::BankQuizQizShadow"
end
