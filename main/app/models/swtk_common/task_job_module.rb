module TaskJobModule
  module Task
    module_function

    module Type
      CreateReport = "create_report"
      ImportResult = "import_result"
      SubmittingOnlineTestResult = "submitting_online_test_results"
    end

    module Status
      InActive = "in_active"
      Active = "active"
      Completed = "completed"
    end
  end

  module Job
    Timeout = 86400 # one day
    LoopInterval = 10 # 10 seconds

    module Type
      CreateReport = "create_report"
      CreatePupilReport = "create_pupil_report"
      CreateClassReport = "create_class_report"
      ImportScore = "import_score"
      GeneratePupilReports = "generate_pupil_reports"
      GenerateGroupReports = "generate_group_reports"
      ConstructReports = "construct_reports"
      Monitoring = "monitoring"
      SubmittingOnlineTestResult = "submitting_online_test_results"
    end

    module Status
      NotInQueue = "notinqueue"
      InQueue = "inqueue"
      Initialization = "initialization"
      Processing = "processing"
      Completed = "completed"
    end
  end
end