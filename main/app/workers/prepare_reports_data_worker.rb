# -*- coding: UTF-8 -*-

class PrepareReportsDataWorker
  include Sidekiq::Worker

  def perform(*args)
    logger = Sidekiq::Logging.logger
    Common::process_sync_template(__method__.to_s()) {|pids|
      pids << fork do # fork new process, begin
        logger.info "#{args}"
        if !args.blank?
          test_id = args[0]
          _, _ = Common::ReportPlus::redis_atai_no_yomidasi_template(Common::SwtkRedis::Ns::Sidekiq, ["tests", test_id, "ckps_qzps_mapping"]){
            ckps_qzps_mapping = Common::ReportPlus::data_ckps_qzps_mapping(test_id, Common::Report::CheckPoints::DefaultLevel)
            ckps_qzps_mapping
          }
          
          _, _ = Common::ReportPlus::redis_atai_no_yomidasi_template(Common::SwtkRedis::Ns::Sidekiq, ["tests", test_id, "qzps_ckps_mapping"]){
            qzps_ckps_mapping = Common::ReportPlus::data_qzps_ckps_mapping(test_id, Common::Report::CheckPoints::DefaultLevel)
            qzps_ckps_mapping
          }
        else
          raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
        end

        # 参数：  _task_uid, _redis_ns, _redis_key,_total_phases
        Common::Job::update_first_job_process_with_redis(args[1], Common::SwtkRedis::Ns::Sidekiq, args[3], args[4])
      end # fork new process, end
    } 
  end
end
