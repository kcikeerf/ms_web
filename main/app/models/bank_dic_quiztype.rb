class BankDicQuiztype < ActiveRecord::Base
  self.primary_key =  "sid"
  
  has_many :bank_subject_qiztype_links, foreign_key: "qiztype_sid"   
  has_many :bank_dic_quiz_subjects, through: :bank_subject_qiztype_links
  accepts_nested_attributes_for :bank_dic_quiz_subjects
end
