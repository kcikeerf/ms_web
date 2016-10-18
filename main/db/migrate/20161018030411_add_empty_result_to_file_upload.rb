class AddEmptyResultToFileUpload < ActiveRecord::Migration
  def change
  	add_column :file_uploads, :empty_result, :string

  	Mongodb::BankPaperPap.all.each{|p|
      if p.orig_file_id && p.score_file_id
        fu = FileUpload.find(p.orig_file_id)
        su = ScoreUpload.find(p.score_file_id)
        fu.empty_result = Pathname.new(fu.current_path).open
        fu.save!
      end
  	}
  end
end
