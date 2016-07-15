class CreateBankDicQuizSubjects < ActiveRecord::Migration
  def change
    create_table :bank_dic_quiz_subjects, id:false do |t|
      t.column :nid, 'INTEGER PRIMARY KEY AUTO_INCREMENT'
      t.string :subject, limit: 50
      t.string :caption, limit: 200
      t.string :desc, limit: 500

      t.timestamps
    end
  end
end
