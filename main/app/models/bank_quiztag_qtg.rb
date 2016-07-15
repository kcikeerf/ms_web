class BankQuiztagQtg < ActiveRecord::Base
  self.primary_key =  "sid"

  include ActiveRecordPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp
end
