class BankCkpCube < ActiveRecord::Base
  self.primary_key = "nid"
  validates :crosstype, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10}

  include ActiveRecordPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp
end
