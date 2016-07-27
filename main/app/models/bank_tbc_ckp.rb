class BankTbcCkp < ActiveRecord::Base
  self.primary_key = "nid"

  include ActiveRecordPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp
  
  belongs_to :bank_nodestructure, foreign_key: "tbs_uid"
  belongs_to :bank_checkpoint_ckp, foreign_key: "ckp_uid3"
end
