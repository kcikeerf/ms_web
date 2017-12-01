module TestModule
  module Test

    Type = {}
    %W{
      xy_default
      zh_dyzn
      zh_fzqn
      zh_rwdy
      zh_kxjs
      zh_xhxx
      zh_jksh
      zh_zrdd
      zh_sjcx
    }.each{|item| Type[item.to_sym] = Common::Locale::i18n("dict.#{item}")}    
        
    module Status
      None = "none"
      Ignore = "ignore"
      New = "new"     
      NotStarted = "not_started"
      NoScore = "no_score"
      Editting = "editting"
      Editted = "editted"
      Analyzing = "analyzing" 
      Analyzed = "analyzed"
      ScoreImporting = "score_importing"
      ScoreImported = "score_imported"
      ReportGenerating = "report_generating"
      ReportCompleted = "report_completed" 
    end

    RollbackStatus = {
      Status::New => I18n.t("tests.status.#{Status::New}"),
      Status::ScoreImported => I18n.t("tests.status.#{Status::ScoreImported}"),
    }

    ExtDataCodeArr = Common::SwtkConstants::AlphabetDownCaseArr + Common::SwtkConstants::AlphabetUpCaseArr + Common::SwtkConstants::NumberArr
    ExtDataPathLength = 6
    ExtDataPathDefaultPrefix = "___"    
  end

  module OnrineTest
    module_function

    module Status
      None = "none"
      Created = "created"
      NoScore = "no_score"
      ScoreImporting = "score_importing"
      ScoreImported = "score_imported"
      ReportGenerating = "report_generating"
      ReportCompleted = "report_completed"
    end

    module Group
      List = ["individual", "total"]
      Individual = "individual"
      Total = "total"
    end

    def update_user_online_test_status _test_id, _user_id, _status
      item = Mongodb::BankTestUserLink.where(bank_test_id: _test_id, user_id: _user_id).first
      return false unless item
      item.update(test_status: _status)
    end
  end
end