# -*- coding: UTF-8 -*-
require 'thwait'

class GenerateReportsJob < ActiveJob::Base
  queue_as :generate_reports

  def self.perform_later(*args)
    Common::method_template_with_rescue(__method__.to_s()) {
      logger.info "#{args}"
      params = args[0]

      if !params[:test_id].blank? && !params[:task_uid].blank? && !params[:top_group].blank?
        # JOB的分处理的数量
        job_tracker = JobList.new({
          :name => "generate reports",
          :task_uid => params[:task_uid],
          :job_type => "generate reports",
          :status => Common::Job::Status::InQueue,
          :process => 0
        })
        job_tracker.save!

        _, _ = Common::ReportPlus::redis_atai_no_yomidasi_template(Common::SwtkRedis::Ns::Sidekiq, [params[:test_id], "ckps_mapping"]){
          ckps_mapping = Common::ReportPlus::data_ckps_mapping(params[:test_id], Common::Report::CheckPoints::DefaultLevel)
          ckps_mapping
        }

        generator_h = {
          :pupil => Mongodb::ReportPupilGenerator.new({:group_type => "pupil"}.merge(params))
        }
        constructor_h = {
          :pupil => Mongodb::ReportConstructor.new({:group_type=>"pupil"}.merge(params))
        }

        end_index = Common::Report::Group::ListArr.find_index(params[:top_group].downcase)
        Common::Report::Group::ListArr[1..end_index].each{|group|
          generator_h[group.to_sym] = Mongodb::ReportGroupGenerator.new({:group_type => group}.merge(params))
          constructor_h[group.to_sym] = Mongodb::ReportConstructor.new({:group_type => group}.merge(params))
        }

        # 清除旧记录
        th_arr = []
        generator_h.each{|k,v|
          th_arr << Thread.new do 
            v.clear_old_data
          end
        }
        ThreadsWait.all_waits(*th_arr)
        job_tracker.update(process: 0.1)

        # 计算
        th_arr = []
        th_arr << Thread.new do 
          generator_h[:pupil].cal_round_1
        end
        ThreadsWait.all_waits(*th_arr)
        job_tracker.update(process: 0.15)


        th_arr = []
        generator_h.each{|k,v|
          th_arr << Thread.new do 
            v.cal_round_1
          end if k != :pupil
        }
        ThreadsWait.all_waits(*th_arr)
        job_tracker.update(process: 0.2)

        th_arr = []
        generator_h.each{|k,v|
          th_arr << Thread.new do 
            v.cal_round_1_5
          end if k != :pupil
        }
        ThreadsWait.all_waits(*th_arr)
        job_tracker.update(process: 0.35)

        th_arr = []
        generator_h.each{|k,v|
          th_arr << Thread.new do 
            v.cal_round_2
          end if k != :pupil
        }
        ThreadsWait.all_waits(*th_arr)
        job_tracker.update(process: 0.5)

        pid = fork do 
          # 组装
          th_arr = []
          constructor_h.each{|k,v|
            th_arr << Thread.new do 
              v.iti_kumigoto_no_kihon_koutiku
            end
          }
          ThreadsWait.all_waits(*th_arr)
          job_tracker.update(process: 0.6)

          th_arr = []
          constructor_h.each{|k,v|
            th_arr << Thread.new do 
              v.ni_kumigoto_no_comment_koutiku
            end
          }
          ThreadsWait.all_waits(*th_arr)
          job_tracker.update(process: 0.8)

          Common::Report::Group::ListArr[1..end_index].reverse.each{|item|
            th_arr = []
            th_arr << Thread.new do 
              constructor_h[item.downcase.to_sym].san_kumikan_no_data_koukan_koutiku
            end
            ThreadsWait.all_waits(*th_arr)
          }
          job_tracker.update(process: 0.9)

          Common::ReportPlus::kumitate_no_owari( Common::SwtkRedis::Ns::Sidekiq, params[:test_id] )
          job_tracker.update(status: Common::Job::Status::Completed)
          job_tracker.update(process: 1.0)
          Signal.trap("TERM") { puts "finished!"; exit }
        end
        logger.info "construct process id: #{pid}"
      else
        raise SwtkErrors::ParameterInvalidError.new(Common::Locale::i18n("swtk_errors.parameter_invalid_error", :message => ""))
      end
    }
  end
end
