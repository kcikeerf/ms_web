# -*- coding: UTF-8 -*-

class ClearReportsGarbageWorker
  include Sidekiq::Worker

  def perform(*args)
    logger = Sidekiq::Logging.logger
    Common::process_sync_template(__method__.to_s()) {|pids|
      pids << fork do # fork new process, begin
        logger.info "#{args}"
        if !args.blank?
          _test_id = args[0]
          _task_uid = args[1]

          target_task = TaskList.where(uid: _task_uid).first
          job_tracker = target_task.job_lists.order(dt_update: :desc).first
          job_tracker.update(process: 1.0)

          target_test = Mongodb::BankTest.where(id: _test_id).first
          target_pap= target_test.bank_paper_pap

          report_redis_key_wildcard = Common::SwtkRedis::Prefix::Reports + "tests/" + _test_id + "/*"
          target_pap.update(paper_status: Common::Paper::Status::ReportCompleted)

          begin
            Common::ReportPlus::kumitate_no_owari_redis(Common::SwtkRedis::Ns::Sidekiq, _test_id)
          rescue Exception => ex
            # do nothing
          end
        else
          raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
        end
      end # fork new process, end
    }    
  end
end
