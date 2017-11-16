# -*- coding: UTF-8 -*-

class ReportsController < ApplicationController
  # use job queue to create every report
  before_action :set_test, only: [:generate_all_reports, :generate_reports, :new_square, :square_v1_1]
  before_action do
    check_resource_tenant(@bank_test.bank_paper_pap) if @bank_test
  end

  # def generate_all_reports
  #   logger.info("====================generate_all_reports: begin")
  #   params.permit!

  #   result = {:task_uid => ""}

  #   begin
  #     # Task info
  #     target_task = @paper.bank_tests[0].tasks.by_task_type(Common::Task::Type::CreateReport).first
  #     task_uid = target_task.nil?? "" :target_task.uid
  #     target_task.touch(:dt_update)

  #     # create a job
  #     Thread.new do
  #       GenerateReportJob.perform_later({
  #         :task_uid => task_uid,
  #         :province =>Common::Locale.hanzi2pinyin(@paper.tenant.area_pcd[:province_name_cn]),
  #         :city => Common::Locale.hanzi2pinyin(@paper.tenant.area_pcd[:city_name_cn]),
  #         :district => Common::Locale.hanzi2pinyin(@paper.tenant.area_pcd[:district_name_cn]),
  #         :school => Common::Locale.hanzi2pinyin(@paper.tenant.name_cn),
  #         :pap_uid => params[:pap_uid]}) 
  #     end

  #     status = 200
  #     result[:task_uid] = task_uid
  #   rescue Exception => ex
  #     status = 500
  #     result[:task_uid] = ex.message
  #   end
  #   logger.info("====================generate_all_reports: end")
  #   render common_json_response(status, result)  
  # end

  def generate_reports
    params.permit!
    status, result = nil, nil
    if ![Common::Paper::Status::ScoreImported].include?( @bank_test.test_status )
      status = 403
      result[:message] = "not suitable operation!"
    end
    status_code,result = Common::template_tk_job_execution_in_controller(status, result) {
      TkJobConnector.new({
        :version => "v1.2",
        :api_name => "reports_generate_xy_reports",
        :http_method => "post",
        :params => {
          :test_id => params[:test_uid],
          :user_id => current_user.id
        }
      })
    }
    render common_json_response(status_code, result)
    # task = @bank_test.tasks.by_task_type("create_report").first
    # #创建job
    # job = Common::Job::create_job_tracker "generate reports",task.uid
    # @bank_test.update(test_status: Common::Test::Status::ReportGenerating)
    # render common_json_response(200, job)
  end

  def generate_union_reports
    union_test = Mongodb::UnionTest.where(_id: params[:union_test_id]).first
    status_code, result = nil, nil
    if union_test
      can_report = true
      # union_test.bank_paper_paps.each {|paper| can_report = can_report&&paper.is_report_completed? }
      union_test.bank_tests.each {|test| can_report = can_report&&test.is_report_completed?}
      if can_report
        union_test_config = (union_test.present?&&union_test.union_config.present?) ? eval(union_test.union_config) : {}
        status_code,result = Common::template_tk_job_execution_in_controller(status_code, result) {
          TkJobConnector.new({
            :version => "v1.2",
            :api_name => "generate_union_tests_reports",
            :http_method => "post",
            :params => {
              :union_test_id => union_test.id.to_s,
              :union_test_config => union_test_config
            }
          })
        }
        # union_test.union_status = Common::Paper::UnionStatus::ReportGenerating
        # union_test.save!
      else
      status_code = 403
      result = {message: I18n.t("reports.messages.union_test.cannot_report")}
      end
    else
      status_code = 500
      result = {message: I18n.t("reports.messages.union_test.not_found")}
    end
    render common_json_response(status_code, result)
  end

  def get_grade_report
    params.permit!

    status = 403
    data = {}
    if params[:report_id].blank?
      status = 500
      data = {message: I18n.t("reports.messages.grade.get_report.failed")}
    else
      report_json = SwtkAliOss::response_report_url(SwtkAliOss::Const[:grade_report_bucket], params[:report_id])
      unless report_json.blank?
        status = 200
        data = {data: JSON.parse(report_json)}
      else
        status = 400
        data = {message: I18n.t("reports.messages.grade.get_report.failed")}
      end
    end
    render common_json_response(status, data)
  end

  def get_class_report
    params.permit!

    status = 403
    data = {}
    if params[:report_id].blank?
      status = 500
      data = {message: I18n.t("reports.messages.class.get_report.failed")}
    else
      report_json = SwtkAliOss::response_report_url(SwtkAliOss::Const[:class_report_bucket], params[:report_id])
      unless report_json.blank?
        status = 200
        data = {data: JSON.parse(report_json)}
      else
        status = 400
        data = {message: I18n.t("reports.messages.class.get_report.failed")}
      end
    end
    render common_json_response(status, data)
  end

  def get_pupil_report
    params.permit!
 
    status = 403
    data = {}
    if params[:report_id].blank?
      status = 500
      data = {message: I18n.t("reports.messages.pupil.get_report.failed")}
    else
      report_json = SwtkAliOss::response_report_url(SwtkAliOss::Const[:pupil_report_bucket], params[:report_id])
      unless report_json.blank?
        status = 200
        data = {data: JSON.parse(report_json)}
      else
        status = 400
        data = {message: I18n.t("reports.messages.pupil.get_report.failed")}
      end
    end
    render common_json_response(status, data)
  end

  def first_login_check_report
    params.permit!

    rum = ReportUrlMapping.where(:codes => params[:codes]).first
    first_flag = rum.first_login

    if first_flag
      redirect_to init_profile_path
      rum.update(:first_login => false)
      return
    end

    params_h = JSON.parse(rum.params_json)

    unless params_h.blank?
      redirect_to new_square_reports_path(:pap_uid=> params_h["pap_uid"])
    else
      render 'errors/error_403', status: 403,  layout: 'error'
    end

  end

  def new_square
    params.permit!

    current_paper = @bank_test.bank_paper_pap#Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first


    loc_h = {
      :province => Common::Locale.hanzi2pinyin(current_tenant.area_pcd[:province_name_cn]),
      :city => Common::Locale.hanzi2pinyin(current_tenant.area_pcd[:city_name_cn]),
      :district => Common::Locale.hanzi2pinyin(current_tenant.area_pcd[:district_name_cn]),
      :school => Common::Locale.hanzi2pinyin(current_tenant.name_cn),
      :grade => current_paper.grade
    }
    #grade_report = Mongodb::GradeReport.where(loc_h).first
    #@default_report_type = "grade"
    #@default_report_id = grade_report._id.to_s
    #@default_report_name = current_paper.heading + I18n.t("dict.ce_shi_zhen_duan_bao_gao")
    #@default_report_type = (current_paper.subject.nil?? I18n.t("dict.unknown") : I18n.t("dict.#{current_paper.subject}"))
    if  current_user.is_tenant_administrator? || current_user.is_analyzer?
      @scope_menus = Location.get_report_menus(Common::Role::Analyzer, params[:pap_uid], loc_h)
    elsif current_user.is_teacher?
      # 暂时将老师和分析员可查看范围一致
      # klass_rooms = current_user.teacher.locations.map{|loc| loc.classroom}
      # loc_h[:classroom] = klass_rooms
      @scope_menus = Location.get_report_menus(Common::Role::Teacher,params[:pap_uid], loc_h)
    elsif current_user.is_pupil?
      loc_h[:classroom] = [current_user.pupil.location.classroom]
      #@scope_menus = current_user.pupil.report_menu params[:pap_uid]
      @scope_menus = Location.get_report_menus(Common::Role::Pupil,params[:pap_uid], loc_h, {:pup_uid => current_user.pupil.uid} )
    else 
      @scope_menus = { 
        :key => "",
        :label => "",
        :report_url => "",
        :items => []}
    end
    render :layout => 'new_report'
  end

  def square_v1_1
    Common::method_template_log_only(__method__.to_s()) {
      params.permit!

      @test_id = @bank_test.id.to_s
      render :layout => '00016110/report'
    }
  end

  def project
    render :layout => false
  end

  def grade
    render :layout => false
  end

  def klass
    render :layout => false
  end

  def pupil
    render :layout => false
  end

  private

  # def set_paper
  #   @paper = Mongodb::BankPaperPap.find(params[:pap_uid])
  #   @paper.current_user_id = 4651#current_user.id
  # end
    def set_test
      @bank_test = Mongodb::BankTest.find(params[:test_uid])
    end
end
