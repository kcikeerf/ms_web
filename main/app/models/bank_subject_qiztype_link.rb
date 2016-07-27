class BankSubjectQiztypeLink < ActiveRecord::Base
  belongs_to :bank_dic_quiz_subject, foreign_key: "subj_nid"
  belongs_to :bank_dic_quiztype, foreign_key: "qiztype_sid"
end
