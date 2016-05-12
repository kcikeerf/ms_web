class BankNodeCatalog < ActiveRecord::Base
  self.primary_key = "uid"

  include ActiveRecordPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp

  belongs_to :bank_nodestructure, foreign_key: "node_uid"
  has_many :bank_ckp_cats, foreign_key: "cat_uid"
  has_many :bank_checkpoint_ckps, through: :bank_ckp_cats

  private
  def init_uid
    self.uid=Time.now.to_snowflake.to_s
  end
end
