# -*- coding: UTF-8 -*-

class MonitoringJob < ActiveJob::Base
  queue_as :monitoring

  def self.perform_later(*args)
    Common::method_template_with_rescue(__method__.to_s()) {
      logger.info "#{args}"
      params = args[0]
      job_groups = params[:job_groups]

      if !job_groups.blank?
        # JOB的分处理的数量
        @stage_number = job_groups.size
        @phase_total = job_groups.flatten.size
        job_tracker = JobList.where(uid: params[:job_uid]).first

        _, papers_ckps_mapping = Common::ReportPlus::redis_atai_no_yomidasi_template(Common::SwtkRedis::Ns::Sidekiq, [params[:test_id], "ckps_qzps_mapping"]){
          ckps_qzps_mapping = Common::ReportPlus::data_ckps_qzps_mapping(params[:test_id], Common::Report::CheckPoints::DefaultLevel)
          ckps_qzps_mapping
        }

        begin
          Timeout::timeout(Common::Job::Timeout){
            next_stage job_tracker, job_groups

            job_tracker.update(status: Common::Job::Status::Completed)
            job_tracker.update(process: 1.0)
          }
        rescue Timeout::Error => ex
          logger.debug "Long Job running timeout(task_uid: #{params[:task_uid]})!!!"
          raise ex
        ensure
          logger.info "Monitoring Job finished!"
        end
      else
        raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
      end
    }
  end

  #
  # [[job1,job2],[job3,job4],...]
  def self.next_stage job_tracker, stages
    return nil if stages.blank?
    current_stage = stages.first
    current_stage.each{|item|
      Thread.new do
        item[:job_class].constantize.perform_later(item[:job_params])
      end
    }

    now = Time.now
    loop do
      if Time.now < now + Common::Job::LoopInterval
        next
      else
        jobs = current_stage.map{|item| JobList.where(uid: item[:job_params][:job_uid]).first }
        raise "Job Number not correct: #{jobs.size}, #{jobs.compact.size}" if jobs.size != jobs.compact.size
        total_job_progress = jobs.map{|j| 
          if j && j.process >= 1.0
            1.0
          else
            0.0
          end
        }.sum
        current_progress = 1.0 - stages.size.to_f/@stage_number + total_job_progress.to_f/(jobs.size*@stage_number)
        job_tracker.update(process: current_progress)
        break if (total_job_progress >= jobs.size)
        now = Time.now
      end
    end
    stages.shift
    next_stage(job_tracker, stages)
  end
end
