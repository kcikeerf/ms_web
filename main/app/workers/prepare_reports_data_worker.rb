# -*- coding: UTF-8 -*-

class PrepareReportsDataWorker
  include Sidekiq::Worker

  def perform(*args)
    Common::method_template_with_rescue(__method__.to_s()) {
      logger.info "#{args}"
      if !args.blank?
        test_id = args[0]
        _, _ = Common::ReportPlus::redis_atai_no_yomidasi_template(Common::SwtkRedis::Ns::Sidekiq, ["tests", test_id, "ckps_qzps_mapping"]){
          ckps_qzps_mapping = Common::ReportPlus::data_ckps_qzps_mapping(test_id, Common::Report::CheckPoints::DefaultLevel)
          ckps_qzps_mapping
        }
        job_tracker.update(process: 0.05)

        _, _ = Common::ReportPlus::redis_atai_no_yomidasi_template(Common::SwtkRedis::Ns::Sidekiq, ["tests", test_id, "qzps_ckps_mapping"]){
          qzps_ckps_mapping = Common::ReportPlus::data_qzps_ckps_mapping(test_id, Common::Report::CheckPoints::DefaultLevel)
          qzps_ckps_mapping
        }
      else
        raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
      end
    }
  end
end
