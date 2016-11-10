# -*- coding: UTF-8 -*-

class ConstructReportsJob < ActiveJob::Base
  queue_as :construct_report

  def perform(*args)
    Common::method_template_with_rescue(__method__.to_s()) {
      logger.info "#{args}"
      params = args[0]

      if Common::Report::Group::ListArr.include?(params[:group_type].downcase)
        # JOB的分处理的数量
        phase_total = 4
        # job_tracker = JobList.new({
        #   :name => "ConstructReportsJob",
        #   :task_uid => params[:task_uid],
        #   :status => Common::Job::Status::InQueue,
        #   :process => 0/phase_total.to_f
        # })
        # job_tracker.save!
        # logger.info "job uid: #{job_tracker.uid}"
        job_tracker = JobList.where(uid: params[:job_uid]).first
        
        logger.info ">>>初始化<<<"
      	construct_report_job = Mongodb::ReportConstructor.new(params)
        job_tracker.update(process: 1/phase_total.to_f)

        logger.info ">>>第1轮组装<<<"
        construct_report_job.iti_kumigoto_no_kihon_koutiku
        job_tracker.update(process: 2/phase_total.to_f)

        logger.info ">>>第2轮组装<<<"
        construct_report_job.ni_kumigoto_no_comment_koutiku
        job_tracker.update(process: 3/phase_total.to_f)

        logger.info ">>>第3轮组装<<<"
        construct_report_job.san_kumikan_no_data_koukan_koutiku
        job_tracker.update(process: 4/phase_total.to_f)

        job_tracker.update(status: Common::Job::Status::Completed)
        job_tracker.update(process: 1.0)
      else
        raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
      end
    }
  end
end
