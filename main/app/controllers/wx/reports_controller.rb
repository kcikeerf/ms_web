class Wx::ReportsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :wx_authenticate!, :except => [:get_indivisual_report_part,:get_indivisual_report_1]
  before_action :wx_set_api_header

  def get_indivisual_report_part
    params.permit!

    status = 403
    data = {}

    if params[:wx_openid].blank?
      status = 500
      data = {message: I18n.t("wx_users.messages.warn.not_wx_user")}
    elsif params[:report_id].blank?
      status = 400
      data = {message: I18n.t("wx_commons.messages.warn.invalid_params")}
    else
      target_report = Mongodb::PupilMobileReport.where(:_id => params[:report_id]).first
      status = 200
      if target_report
        data = {message: I18n.t("wx_reports.messages.info.got_report"), report_json: target_report.simple_report_wx_notbinded}
      else
        data = {message: I18n.t("wx_reports.messages.info.no_report")}
      end
    end

    render common_json_response(status, data)
  end

  def get_indivisual_report_1
    params.permit!

    status = 403
    data = {}

    current_pupil = wx_current_user.nil?? nil : wx_current_user.pupil
    if false #current_pupil.nil?
      status = 500
      data = { message: I18n.t("wx_users.messages.warn.invalid_binding_params") }
    elsif !params[:report_id].blank?
      #target_report = Mongodb::PupilMobileReport.where(:pup_uid=>current_pupil.uid.to_s, :_id => params[:report_id]).first
      target_report = Mongodb::PupilMobileReport.where(:_id => params[:report_id]).first
      status = 200
      if target_report
      	report_json = target_report.report_json.blank?? Common::Report::Format::PupilMobile : target_report.report_json
      	data = {message: I18n.t("wx_reports.messages.info.got_report"), report_json: report_json}
      else
      	data = {message: I18n.t("wx_reports.messages.info.no_report")}
      end
    else
      status = 500
      data = {message: I18n.t("wx_reports.messages.error.got_report_failed")}
    end
    render common_json_response(status, data)
  end
end
