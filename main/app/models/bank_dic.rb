class BankDic < ActiveRecord::Base
  self.primary_key =  "sid"
  has_many :bank_dic_items, foreign_key: "dic_sid"
  accepts_nested_attributes_for :bank_dic_items

  include ActiveRecordPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  def self.list_difficulty
    result = {"difficulty" => { "label" => Common::Locale::i18n("dict.difficulty"), "items" =>[]} }
    dic = self.where("sid = ?", "difficulty").first
    return result if dic.nil?
    result = dic.bank_dic_items.map{|item|
      {"label" => Common::Locale::i18n("dict.#{item.sid}"), "sid" => item.sid}
    }
    return result    
  end

end
