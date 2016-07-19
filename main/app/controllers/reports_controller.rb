class ReportsController < ApplicationController
  # use job queue to create every report
  
  def generate_all_reports
    params.permit!

    result = {:task_uid => ""}

    begin
      current_pap = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first

      #create a task to follow all the jobs
      task_name = format_report_task_name current_pap.heading
      p "task_name", task_name
      new_task = TaskList.new(
        name: task_name,
        #type: Common::Task::Type::CreateReport,
#        ana_uid: current_user.analyzer.uid,
        pap_uid: params[:pap_uid])
      new_task.save!

      # create a job
#      gcr_jpb = GenerateReportJob.new #loc_id, paper
#      p "job=======>",gcr_jpb
      Thread.new do
        GenerateReportJob.perform_later({
          :task_uid => new_task.uid,
          :province =>Common::Locale.hanzi2pinyin(params[:province]),
          :city => Common::Locale.hanzi2pinyin(params[:city]),
          :district => Common::Locale.hanzi2pinyin(params[:district]),
          :school => Common::Locale.hanzi2pinyin(params[:school]),
          :pap_uid => params[:pap_uid]}) 
      end

      status = 200
      result[:task_uid] = new_task.uid
    rescue Exception => ex
      status = 500
      result[:task_uid] = ex.message
    end
    render common_json_response(status, result)  
  end

  def get_grade_report
    params.permit!

    result = response_json

    current_report = Mongodb::GradeReport.where(_id: params[:report_id]).first

    report_json = JSON.parse(current_report.report_json)
     
    result = response_json(200, report_json)

    render :json => result
  end

  def get_class_report
    params.permit!

    result = response_json

    current_report = Mongodb::ClassReport.where(_id: params[:report_id]).first

    report_json = JSON.parse(current_report.report_json)
     
    result = response_json(200, report_json)

    render :json => result
  end

  def get_pupil_report
    params.permit!
 
    result = response_json

    current_report = Mongodb::PupilReport.where(_id: params[:report_id]).first

    report_json = JSON.parse(current_report.report_json)
     
    result = response_json(200, report_json)

    render :json => result
  end

  # reports index page
  def square
    params.permit!

    current_paper = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first

    loc_h = {
      :province => Common::Locale.hanzi2pinyin(current_paper.province),
      :city => Common::Locale.hanzi2pinyin(current_paper.city),
      :district => Common::Locale.hanzi2pinyin(current_paper.district),
      :school => Common::Locale.hanzi2pinyin(current_paper.school),
      :grade => current_paper.grade
    }
    grade_report = Mongodb::GradeReport.where(loc_h).first

    @default_report = "/grade_reports/index?type=grade_report&report_id=#{grade_report._id}"
    @default_report_name = current_paper.heading + I18n.t("dict.ce_shi_zhen_duan_bao_gao")
    @default_report_subject = I18n.t("dict.#{current_paper.subject}") + "&middot" + I18n.t("dict.nian_ji_bao_gao")
    
    @default_report_title = current_paper.heading + I18n.t("dict.ce_shi_zhen_duan_bao_gao")
    @default_report_subject = I18n.t("dict.#{current_paper.subject}")
    if current_user.is_analyzer?
      @scope_menus = Location.get_grade_and_children(params[:pap_uid], loc_h)
    elsif current_user.is_teacher?
      klass_rooms = current_user.teacher.locations.map{|loc| loc.class_room}
      loc_h[:class_room] = klass_rooms
      @scope_menus = Location.get_grade_and_children(params[:pap_uid], loc_h)
    elsif current_user.is_pupil?
      @scope_menus = current_user.pupil.report_menu params[:pap_uid]
    else 
      @scope_menus = { 
        :key => "",
        :label => "",
        :report_url => "",
        :items => []}
    end

=begin
    if current_user.is_analyzer?
      
    elsif current_user.is_teacher?

    elsif current_user.is_pupil?

    end
=end
    render :layout => 'report'
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
      render 'errors/403', status: 403,  layout: 'error'
    end

  end

  def new_square
    params.permit!

    current_paper = Mongodb::BankPaperPap.where(_id: params[:pap_uid]).first

    loc_h = {
      :province => Common::Locale.hanzi2pinyin(current_paper.province),
      :city => Common::Locale.hanzi2pinyin(current_paper.city),
      :district => Common::Locale.hanzi2pinyin(current_paper.district),
      :school => Common::Locale.hanzi2pinyin(current_paper.school),
      :grade => current_paper.grade
    }
    grade_report = Mongodb::GradeReport.where(loc_h).first
    @default_report = "/grade_reports/index?type=grade_report&report_id=#{grade_report._id}"
    @default_report_name = current_paper.heading + I18n.t("dict.ce_shi_zhen_duan_bao_gao")
    @default_report_subject = I18n.t("dict.#{current_paper.subject}") + "&middot" + I18n.t("dict.nian_ji_bao_gao")
    if current_user.is_analyzer?
      @scope_menus = Location.get_grade_and_children(params[:pap_uid], loc_h)
    elsif current_user.is_teacher?
      klass_rooms = current_user.teacher.locations.map{|loc| loc.class_room}
      loc_h[:class_room] = klass_rooms
      @scope_menus = Location.get_grade_and_children(params[:pap_uid], loc_h)
    elsif current_user.is_pupil?
      @scope_menus = current_user.pupil.report_menu params[:pap_uid]
    else 
      @scope_menus = { 
        :key => "",
        :label => "",
        :report_url => "",
        :items => []}
    end
    render :layout => 'breport'
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
  def format_report_task_name prefix
    prefix + "_" +Common::Task::Type::CreateReport
  end
end
