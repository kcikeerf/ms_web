class BankNodestructureSubjectCkp < ActiveRecord::Base
	belongs_to :bank_nodestructure, foreign_key: 'node_structure_uid'
	belongs_to :bank_subject_checkpoint_ckp, foreign_key: 'subject_ckp_uid'

end
