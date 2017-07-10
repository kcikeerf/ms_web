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
    module_function

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

    def update_first_job_process_with_redis  _task_uid, _redis_ns, _redis_key,_total_phases
      Common::SwtkRedis::incr_key(_redis_ns, _redis_key)
      process_value = Common::SwtkRedis::get_value(_redis_ns, _redis_key).to_f
      target_task = TaskList.where(uid: _task_uid).first
      return false unless target_task
      job_tracker = target_task.job_lists.order(dt_update: :desc).first
      return false unless job_tracker
      job_tracker.update(process: process_value/_total_phases)  
      return true
    end
  end
end