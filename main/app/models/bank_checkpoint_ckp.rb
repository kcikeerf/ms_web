class BankCheckpointCkp < ActiveRecord::Base
  self.primary_key = "uid"

#  to be implemented when the range is clear
#
#  validates :is_entity, 

  include ActiveRecordPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp  

  before_create :init_uid

  has_many :bank_ckp_comments, foreign_key: "ban_uid"

  has_many :bank_tbc_ckps
  has_many :bank_nodestructures, through: bank_tbc_ckps

  private
  def init_uid
    self.uid=Time.now.to_snowflake.to_s
  end

end
