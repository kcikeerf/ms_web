# -*- coding: UTF-8 -*-

class GeneratePupilReportsWorker
  include Sidekiq::Worker
  
  def perform(*args)
    logger = Sidekiq::Logging.logger
    Common::process_sync_template(__method__.to_s()) {|pids|
      pids << fork do # fork new process, begin
        logger.info "#{args}"
        if !args.blank?
          paramsh = {
            :test_id => args[0],
            :task_uid => args[1],
            :top_group => args[2],
            :group_type => Common::Report::Group::Pupil
          }
          paramsh.merge!({:tenant_uids => [args[3]]}) if !args[3].blank?
          process_ins = Mongodb::ReportPupilGenerator.new(paramsh)
          process_ins.clear_old_data
          process_ins.cal_round_1
        else
          raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
        end
      end # fork new process, end
    } 
  end
end
