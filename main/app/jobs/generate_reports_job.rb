# -*- coding: UTF-8 -*-
require 'thwait'

class GenerateReportsJob < ActiveJob::Base
  queue_as :generate_reports

  def self.perform_later(*args)
    Common::method_template_with_rescue(__method__.to_s()) {
      logger.info "#{args}"
      params = args[0]

      if !params[:test_id].blank? && !params[:task_uid].blank? && !params[:top_group].blank?
        target_test = Mongodb::BankTest.where(id: params[:test_id]).first
        target_pap= target_test.bank_paper_pap
        target_pap.update(paper_status: Common::Paper::Status::ReportGenerating)

        # JOB的分处理的数量
        job_tracker = JobList.new({
          :name => "generate reports",
          :task_uid => params[:task_uid],
          :job_type => "generate reports",
          :status => Common::Job::Status::InQueue,
          :process => 0
        })
        job_tracker.save!

        _, _ = Common::ReportPlus::redis_atai_no_yomidasi_template(Common::SwtkRedis::Ns::Sidekiq, ["tests", params[:test_id], "ckps_qzps_mapping"]){
          ckps_qzps_mapping = Common::ReportPlus::data_ckps_qzps_mapping(params[:test_id], Common::Report::CheckPoints::DefaultLevel)
          ckps_qzps_mapping
        }
        job_tracker.update(process: 0.05)

        _, _ = Common::ReportPlus::redis_atai_no_yomidasi_template(Common::SwtkRedis::Ns::Sidekiq, ["tests", params[:test_id], "qzps_ckps_mapping"]){
          qzps_ckps_mapping = Common::ReportPlus::data_qzps_ckps_mapping(params[:test_id], Common::Report::CheckPoints::DefaultLevel)
          qzps_ckps_mapping
        }
        job_tracker.update(process: 0.1)

        # generator_h = {
        #   "pupil" => Mongodb::ReportPupilGenerator.new({:group_type => "pupil"}.merge(params))
        # }
        # constructor_h = {
        #   "pupil" => Mongodb::ReportConstructor.new({:group_type=>"pupil"}.merge(params))
        # }

        genreator_arr = [Mongodb::ReportPupilGenerator.new({:group_type => "pupil"}.merge(params))]
        constructor_arr = [Mongodb::ReportConstructor.new({:group_type=>"pupil"}.merge(params))]

        end_index = Common::Report::Group::ListArr.find_index(params[:top_group].downcase)
        # Common::Report::Group::ListArr[0..end_index].each{|group|
        #   generator_h[group] = Mongodb::ReportGroupGenerator.new({:group_type => group}.merge(params))
        #   constructor_h[group] = Mongodb::ReportConstructor.new({:group_type => group}.merge(params))
        # }
        Common::Report::Group::ListArr[1..end_index].each{|group|
          genreator_arr << Mongodb::ReportGroupGenerator.new({:group_type => group}.merge(params))
          constructor_arr << Mongodb::ReportConstructor.new({:group_type => group}.merge(params))
        }


        # 清除旧记录
        # th_arr = []
        genreator_arr.each{|item|
          # th_arr << Thread.new do 
            item.clear_old_data
          # end
        }
        # ThreadsWait.all_waits(*th_arr)
        job_tracker.update(process: 0.2)

        # 计算1
        # th_arr = []
        # th_arr << Thread.new do 
        #   generator_h[:pupil].cal_round_1
        # end
        # ThreadsWait.all_waits(*th_arr)
        # job_tracker.update(process: 0.15)


        # th_arr = []
        genreator_arr.each{|item|
          item.cal_round_1
        }
        job_tracker.update(process: 0.3)

        # 计算1.5
        genreator_arr.each{|item|
          item.cal_round_1_5
        }
        job_tracker.update(process: 0.4)

        # 计算2
        genreator_arr.each{|item|
          item.cal_round_2
        }
        job_tracker.update(process: 0.5)

        #pid = fork do 
        # 组装1
        constructor_arr.each{|item|
          item.iti_kumigoto_no_kihon_koutiku
        }
        job_tracker.update(process: 0.7)

        # 组装2
        constructor_arr.each{|item|
          item.ni_kumigoto_no_comment_koutiku
        }
        job_tracker.update(process: 0.8)

        # 结束处理
        constructor_arr.each{|item|
          item.owari
        }
        job_tracker.update(process: 0.9)

        job_tracker.update(status: Common::Job::Status::Completed)
        job_tracker.update(process: 1.0)

        target_pap.update(paper_status: Common::Paper::Status::ReportCompleted)
        #  Signal.trap("TERM") { puts "finished!"; exit }
        #end
        #logger.info "construct process id: #{pid}"
      else
        raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
      end
    }
  end
end
