class BankNodeCatalogSubjectCkp < ActiveRecord::Base
	belongs_to :bank_node_catalog, foreign_key: 'node_catalog_uid'
	belongs_to :bank_subject_checkpoint_ckp, foreign_key: 'subject_ckp_uid'

end
