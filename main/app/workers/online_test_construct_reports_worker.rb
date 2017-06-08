# -*- coding: UTF-8 -*-

class OnlineTestConstructReportsWorker
  include Sidekiq::Worker

  def perform(*args)
    logger = Sidekiq::Logging.logger
    Common::process_sync_template(__method__.to_s()) {|pids|
      pids << fork do # fork new process, begin
        logger.info "#{args}"
        if !args.blank?
          paramsh = {
            :test_id => args[0],
            :group_type => args[1],
            :test_type => args[3]
          }
          paramsh.merge!({:tenant_uids => [args[2]]}) if !args[2].blank?
          process_ins = Mongodb::OnlineTestZhFzqnGroupConstructor.new(paramsh)
          process_ins.construct_round_1
          process_ins.pre_owari
          process_ins.owari
        else
          raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
        end
      end # fork new process, end
    } 
  end
end
