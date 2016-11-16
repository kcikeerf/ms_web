# -*- coding: UTF-8 -*-

class GeneratePupilReportsJob < ActiveJob::Base
  queue_as :generate_pupil_report

  def self.perform_later(*args)
    Common::method_template_with_rescue(__method__.to_s()) {
      logger.info "#{args}"
      params = args[0]
      if ["pupil"].include?(params[:group_type])
        # JOB的分处理的数量
        phase_total = 3
        # job_tracker = JobList.new({
        #   :name => "GeneratePupilReportsJob",
        #   :task_uid => params[:task_uid],
        #   :status => Common::Job::Status::InQueue,
        #   :process => 0/phase_total.to_f
        # })
        # job_tracker.save!
        # logger.info "job uid: #{job_tracker.uid}"
        job_tracker = JobList.where(uid: params[:job_uid]).first

        logger.info ">>>初始化<<<"
     	  generate_report_job = Mongodb::ReportPupilGenerator.new(params)
        job_tracker.update(process: 1/phase_total.to_f)

        logger.info ">>>清除旧数据<<<"
        generate_report_job.clear_old_data
        job_tracker.update(process: 2/phase_total.to_f)

        logger.info ">>>第1轮计算<<<"
        generate_report_job.cal_round_1
        job_tracker.update(process: 3/phase_total.to_f)

        job_tracker.update(status: Common::Job::Status::Completed)
        job_tracker.update(process: 1.0)
      else
        raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
      end
    }
  end
end
