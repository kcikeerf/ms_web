class BankDicQuizSubject < ActiveRecord::Base
  self.primary_key = "nid"
  
  has_many :bank_subject_qiztype_links, foreign_key: "subj_nid"
  has_many :bank_dic_quiztypes, through: :bank_subject_qiztype_links
  accepts_nested_attributes_for :bank_dic_quiztypes  

  def self.list_quiztypes
    result = {}
    self.all.each{|item|
      result[item.subject] = item.bank_dic_quiztypes.map{|type| {"label" => Common::Locale::i18n("dict.#{type.sid}"), "type" => type.sid}}  
    }
    return result
  end
end
