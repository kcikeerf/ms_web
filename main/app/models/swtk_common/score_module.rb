module ScoreModule
  module Score
    module_function

    module Thread
      NumPerTh = 50
      ThNum = 1#4
      ThNumMax =20 
    end

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

    def upload_filled_result params
      fs = ScoreUpload.where({:test_id => params[:test_id], :tenant_uid => params[:tenant_uid]}).first
      fs = ScoreUpload.new unless fs
      fs.filled_file = params[:file]
      fs.test_id = params[:test_id]
      fs.tenant_uid = params[:tenant_uid]
      fs.save!
      return fs
    end
  end
end