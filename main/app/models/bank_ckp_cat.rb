class BankCkpCat < ActiveRecord::Base
  self.primary_key = "nid"

  #concerns
  include TimePatch

  belongs_to :bank_node_catalog, foreign_key: "cat_uid"
  belongs_to :bank_checkpoint_ckp, foreign_key: "ckp_uid"
end
