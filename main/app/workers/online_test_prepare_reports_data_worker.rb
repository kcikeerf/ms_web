# -*- coding: UTF-8 -*-

class OnlineTestPrepareReportsDataWorker
  include Sidekiq::Worker

  def perform(*args)
    logger = Sidekiq::Logging.logger
    Common::process_sync_template(__method__.to_s()) {|pids|
      pids << fork do # fork new process, begin
 		logger.info "OnlineTestPrepareReportsDataWorker"

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

          Mongodb::TestReportUrl.delete_all(test_id: test_id) if test_id
        else
          raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
        end

      end # fork new process, end
    } 
  end
end
