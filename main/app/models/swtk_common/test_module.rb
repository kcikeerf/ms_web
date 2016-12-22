module TestModule
  module Test
    module Status
      None = "none"
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
  end

  module OnrineTest
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
  end
end