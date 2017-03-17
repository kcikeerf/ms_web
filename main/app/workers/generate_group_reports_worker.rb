# -*- coding: UTF-8 -*-

class GenerateGroupReportsWorker
  include Sidekiq::Worker

  def perform(*args)
    Common::method_template_with_rescue(__method__.to_s()) {
      logger.info "#{args}"
      if !args.blank?
        paramsh = {
          :test_id => args[0],
          :task_uid => args[1],
          :top_group => args[2],
          :group_type => args[3]
        }
        paramsh.merge!({:tenant_uids => [args[4]]}) if !args[4].blank?
        process_ins = Mongodb::ReportGroupGenerator.new(paramsh)
        process_ins.clear_old_data
        process_ins.cal_round_1
        process_ins.cal_round_1_5
        process_ins.cal_round_2
      else
        raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
      end
    }
  end
end
