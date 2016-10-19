module TaskJobModule
  module Task
    module_function

    module Type
      CreateReport = "create_report"
      ImportResult = "import_result"
    end

    module Status
      InActive = "in_active"
      Active = "active"
      Complete = "completed"
    end
  end

  module Job
    module Type
      CreateReport = "create_report"
      CreatePupilReport = "create_pupil_report"
      CreateClassReport = "create_class_report"
      ImportScore = "import_score"
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