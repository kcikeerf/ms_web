class Wx::AuthsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :wx_set_api_header

  def wx_bind
    params.permit!

    status = 403
    data = {}

    unless params[:school_number].blank? && params[:stu_number].blank? && params[:wx_openid].blank?
      name_str = params[:school_number] + "_" + params[:stu_number]
      target_user = User.where(:name => name_str).first
      target_pupil = target_user.nil?? nil:target_user.pupil
      if target_user && target_pupil
      	if target_user.update(:wx_openid => params[:wx_openid].strip)
          status = 200
          data = {message: I18n.t("wx_users.messages.info.wx_binded")}
        else
          status = 500
          data = {message: I18n.t("wx_users.messages.error.wx_not_binded")}
        end
      else
        status = 500
      	data = {message: I18n.t("wx_users.messages.warn.invalid_pupil")}
      end
    else
      status = 400
      data = {message:I18n.t("wx_commons.messages.warn.invalid_params")}
    end
    render common_json_response(status, data)
  end
end
