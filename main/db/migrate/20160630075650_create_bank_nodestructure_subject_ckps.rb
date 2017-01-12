class CreateBankNodestructureSubjectCkps < ActiveRecord::Migration
  def change
    create_table :bank_nodestructure_subject_ckps do |t|
    	t.string :node_structure_uid, null: false, limit: 50
    	t.string :subject_ckp_uid, null: false, limit: 50
      t.timestamps null: false
    end
  end
end
