# -*- coding: UTF-8 -*-

class ClearReportsGarbageWorker
  include Sidekiq::Worker

  def perform(*args)
    Common::method_template_with_rescue(__method__.to_s()) {
      logger.info "#{args}"
      if !args.blank?
        test_id = args[0]
        task_uid = args[1]
        target_task = TaskList.where(uid: task_uid).first
        job_tracker = target_task.job_lists.order(dt_update: :desc).first
        job_tracker.update(process: 1.0)
        target_test = Mongodb::BankTest.where(id: test_id).first
        target_pap= target_test.bank_paper_pap      	
        report_redis_key_wildcard = Common::SwtkRedis::Prefix::Reports + "tests/#{test_id}/*"
        Common::SwtkRedis::del_keys(Common::SwtkRedis::Ns::Sidekiq, report_redis_key_wildcard)
        target_pap.update(paper_status: Common::Paper::Status::ReportCompleted)
      else
        raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
      end
    }
  end
end
