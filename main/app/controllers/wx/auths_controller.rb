class Wx::AuthsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def wx_bind
    params.permit!

    result = response_json

    unless params[:school_number].blank? && params[:stu_number].blank? && params[:wx_openid].blank?
      name_str = params[:school_number] + "_" + params[:stu_number]
      target_user = User.where(:name => name_str).first
      target_pupil = target_user.nil?? nil:target_user.pupil
      if target_user && target_pupil
      	if target_user.update(:wx_openid => params[:wx_openid].strip)
          result =response_json(200, {message: I18n.t("wx_users.messages.info.wx_binded")})
        else
          result = response_json(500, {message: I18n.t("wx_users.messages.error.wx_not_binded")})
        end
      else
      	result = response_json(500, {message: I18n.t("wx_users.messages.warn.invalid_pupil")})
      end
    else
      result = response_json(400, {message:I18n.t("wx_commons.messages.warn.invalid_params")}) 
    end
    render :json => result
  end
end
