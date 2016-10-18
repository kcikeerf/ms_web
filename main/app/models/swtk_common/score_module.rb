module ScoreModule
  module Score
    module_function

    module Constants
      AllowUserNumber = 5000
      AllowScoreNumber = 1000
    end

    # def create_empty_score file_path
    #   fs = ScoreUpload.new
    #   fs.empty_file = Pathname.new(file_path).open
    #   fs.save!
    #   return fs 
    # end

    def create_usr_pwd params
      fs = ScoreUpload.where(id: params[:score_file_id]).first
      fs.usr_pwd_file = Pathname.new(params[:file_path]).open
      fs.save!
      return fs 
    end

    def upload_filled_score params
      fs = ScoreUpload.new
      fs.filled_file = params[:filled_file]
      fs.save!
      return fs
    end
  end
end