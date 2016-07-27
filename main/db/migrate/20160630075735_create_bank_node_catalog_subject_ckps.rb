class CreateBankNodeCatalogSubjectCkps < ActiveRecord::Migration
  def change
    create_table :bank_node_catalog_subject_ckps do |t|
    	t.string :node_catalog_uid, null: false, limit: 50
    	t.string :subject_ckp_uid, null: false, limit: 50
      t.timestamps null: false
    end
  end
end
