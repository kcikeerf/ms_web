class CreateBankSubjectQiztypeLinks < ActiveRecord::Migration
  def change
    create_table :bank_subject_qiztype_links do |t|
      t.string :subj_nid, limit: 50
      t.string :qiztype_sid, limit: 50

      t.timestamps
    end
  end
end
