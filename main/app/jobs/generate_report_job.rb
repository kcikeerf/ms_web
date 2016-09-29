# -*- coding: UTF-8 -*-

class GenerateReportJob < ActiveJob::Base
  queue_as :report

  def self.perform_later(*args)
    begin
      params = args[0]
      logger.info "============>>Generate Report: Begin<<=============="
      logger.debug "#{args}"
      #logger.debug "job_id: #{params[:track_id]}"
      logger.debug "params: #{params}"

      job_tracker = JobList.new(name: "generate a job",
                                #job_id: self.job_id,
                                task_uid: params[:task_uid],
                                status: Common::Job::Status::InQueue)
      job_tracker.save

      logger.debug "job_tracker: #{job_tracker}"
      job_tracker.update(status: Common::Job::Status::Processing)
      phase_total = 17

      # 清空旧数据
      logger.info "============>>>Generate Report: 清空旧数据<<<============"
      robj = Mongodb::ReportGenerator.new(params)
      robj.clear_old_data
      job_tracker.update(process: 0.5/phase_total.to_f)

      # 初始化
      logger.info "============>>>Generate Report: 初始化<<<============"
      job_tracker.update(process: 1/phase_total.to_f)

      #初始化 1
      logger.info ">>>初始化 1<<<"
      robj.cal_init1
      job_tracker.update(process: 2/phase_total.to_f)

      #初始化 2
      logger.info ">>>初始化 2<<<"
      robj.add_materials1
      job_tracker.update(process: 3/phase_total.to_f)

      #初始化 3
      logger.info ">>>初始化 3<<<"
      robj.cal_init2
      job_tracker.update(process: 4/phase_total.to_f)

      #初始化 4
      logger.info ">>>初始化 4<<<"
      robj.add_materials2
      job_tracker.update(process: 5/phase_total.to_f)

      #初始化 5
      logger.info ">>>初始化 5<<<"
      robj.cal_init3
      job_tracker.update(process: 6/phase_total.to_f)

      #初始化 6
      logger.info ">>>初始化 6<<<"
      robj.cal_init4
      job_tracker.update(process: 7/phase_total.to_f)
    
      ################年级报告
      # 组装 1
      logger.info "============>>Generate Report: 年级4分位<<<============"
      robj.construct_grade_4sections
      job_tracker.update(process: 8/phase_total.to_f)

      # 组装 2
      logger.info "============>>Generate Report: 各班指标表现水平图<<<============"
      robj.construct_each_klass_each_ckp_horizon
      job_tracker.update(process: 9/phase_total.to_f)

      ################班级报告
      # 组装 3
      logger.info "============>>Generate Report: 年级，班级诊断图<<<============"
      robj.construct_gra_cls_charts
      job_tracker.update(process: 10/phase_total.to_f)

      logger.info "============>>Generate Report: 年级，班级三维指标分型图<<<============"
      robj.construct_grade_dimesion_disperse_chart
      job_tracker.update(process: 11/phase_total.to_f)

      # 组装 4
      logger.info "============>>Generate Report: 年级，班级各分数段人数比例<<<============"
      robj.construct_each_level_pupil_number
      job_tracker.update(process: 12/phase_total.to_f)

      # 组装 5
      logger.info "============>>Generate Report: 班级数据表（班级，学生）<<<============"
      robj.construct_data_table
      job_tracker.update(process: 13/phase_total.to_f)
 
      # 组装 6
      logger.info "============>>Generate Report: 年级，班级答题情况统计<<<============"
      robj.construct_gra_cls_each_qizpoint_average_percent
      job_tracker.update(process: 14/phase_total.to_f)

      # 组装 7
      logger.info "============>>Generate Report: 班级测试三维指标的评价<<<============"
      robj.construct_class_quiz_comments
      job_tracker.update(process: 15/phase_total.to_f)

      # 组装 8
      logger.info "============>>Generate Report: 个人报告诊断图<<<============"
      robj.construct_pupil_charts
      job_tracker.update(process: 16/phase_total.to_f)

      # 组装 9
      logger.info "============>>Generate Report: 诊断及改进建议<<<============"
      robj.construct_pupil_quiz_comments

      robj.when_completed
      job_tracker.update(status: Common::Job::Status::Completed)
      job_tracker.update(process: 1.0)
    rescue Exception => ex
      logger.info "===!Excepion!==="
      logger.info "[message]"
      logger.warn ex.message
      logger.info "[backtrace]"
      logger.warn ex.backtrace
    ensure 
      logger.info "============>>Generate Class Report: End<<=============="
    end
  end
end
