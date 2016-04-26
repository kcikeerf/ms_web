class BankCheckpointCkp < ActiveRecord::Base
  include Tenacity

  self.primary_key = "uid"

#  to be implemented when the range is clear
#
#  validates :is_entity, 

  include ActiveRecordPatch
  before_create :set_create_time_stamp
  before_save :set_update_time_stamp  

  before_create :init_uid

  has_many :bank_ckp_comments, foreign_key: "ban_uid"
  has_many :bank_tbc_ckps, foreign_key: "ckp_uid3"
  has_many :bank_nodestructures, through: :bank_tbc_ckps

  t_has_many :bank_ckp_qzps, class_name: "Mongodb::BankCkpQzp", foreign_key: "ckp_uid"

  accepts_nested_attributes_for :bank_ckp_comments,:bank_nodestructures

  private
  def init_uid
    self.uid=Time.now.to_snowflake.to_s
  end

end
