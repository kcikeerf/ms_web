# -*- coding: UTF-8 -*-

class ConstructReportsWorker
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
        process_ins = Mongodb::ReportConstructor.new(paramsh)
        process_ins.iti_kumigoto_no_kihon_koutiku
        process_ins.pre_owari
        process_ins.owari
      else
        raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
      end
    }
  end
end
