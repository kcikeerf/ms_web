class BankDic < ActiveRecord::Base
  self.primary_key =  "sid"
  has_many :bank_dic_items, foreign_key: "dic_sid"

  include ActiveRecordPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

end
