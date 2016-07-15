class Wx::ReportsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :wx_authenticate!

  def get_indivisual_report_1
    params.permit!

    result = response_json

    current_pupil = wx_current_user.pupil
    if current_pupil.nil?
      result = response_json(500, {message: I18n.t("wx_users.messages.warn.invalid_wx_user")})
    elsif !params[:report_id].blank?
      target_report = Mongodb::PupilMobileReport.where(:pup_uid=>current_pupil.uid.to_s, :_id => params[:report_id]).first
      if target_report
      	report_json = target_report.report_json.blank?? Common::Report::Format::PupilMobile : target_report.report_json

      	result = response_json(200, {message: I18n.t("wx_users.messages.info.got_report"), report_json: report_json})
      else
      	result = response_json(200, {message: I18n.t("wx_users.messages.info.no_report")})
      end
    else
      result = response_json(500, {message: I18n.t("wx_users.messages.error.got_report_failed")})
    end
    render :json => result
  end
end
