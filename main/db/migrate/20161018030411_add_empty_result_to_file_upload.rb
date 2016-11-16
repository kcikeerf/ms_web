class AddEmptyResultToFileUpload < ActiveRecord::Migration
  def change
  	add_column :file_uploads, :empty_result, :string

  	Mongodb::BankPaperPap.all.each{|p|
      if p.orig_file_id && p.score_file_id
        fu = FileUpload.where(id: p.orig_file_id).first
        su = ScoreUpload.where(id: p.score_file_id).first
        next if fu.nil? || su.nil?
        fu.empty_result = Pathname.new(su.empty_file.current_path).open if File.exists?(su.empty_file.current_path)
        fu.save!
      end
  	}
  end
end
