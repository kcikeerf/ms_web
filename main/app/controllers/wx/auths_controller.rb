class Wx::AuthsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :wx_set_api_header

  def check_bind
    params.permit(:wx_openid, :user_name)

    status = 403
    data = {}

    if !params[:wx_openid].blank? && !params[:user_name].blank?

      target_user = User.where(name: params[:user_name]).first
      target_wx_user = WxUser.where(:wx_openid => params[:wx_openid]).first

      if target_user && target_wx_user
        if target_wx_user.binded_user? target_user.name
          if target_user.role_obj.nil?
            status = 500
            data = {message: I18n.t("wx_users.messages.warn.invalid_binded")}
          else
            status = 200
            data = {message: I18n.t("wx_users.messages.info.is_binded")}
          end
        else
          status = 500
          data = {message: I18n.t("wx_users.messages.warn.not_binded")}
        end
      else
        status = 500
        data = {message: I18n.t("wx_users.messages.warn.not_binded")}
      end
    else
      status = 400
      data = {message:I18n.t("wx_commons.messages.warn.invalid_params")}
    end
    render common_json_response(status, data)
  end

  def wx_bind
    params.permit!

    status = 403
    data = {}

    if !params[:user_name].blank? && !params[:password].blank? && !params[:wx_openid].blank?

      target_user = User.where(name: params[:user_name]).first
      target_wx_user = WxUser.where(:wx_openid => params[:wx_openid]).first
      
      if target_user && target_user.valid_password?(params[:password])
        begin
          if target_wx_user
            if target_wx_user.binded_user? params[:user_name]
              status = 200
              data = {message: I18n.t("wx_users.messages.info.is_binded")}
            else
              target_wx_user.users << target_user
              status = 200
              data = {message: I18n.t("wx_users.messages.info.wx_binded")}
            end
          else
            current_wx_user = WxUser.new({
              :wx_openid => params[:wx_openid],
              :users => [target_user]
            })
            current_wx_user.save!
            status = 200
            data = {message: I18n.t("wx_users.messages.info.wx_binded")}
          end
        rescue Exception => ex
          status = 500
          data = {message: ex.backtrace}#I18n.t("wx_users.messages.error.wx_not_binded")}
        end
      else
        status = 500
        data = {message:I18n.t("wx_users.messages.error.login_failed")}
      end
    else
      status = 400
      data = {message:I18n.t("wx_commons.messages.warn.invalid_params")}
    end
    render common_json_response(status, data)
  end

  def get_binded_users
    params.permit!

    status = 403
    data = {}

    if !params[:wx_openid].blank?
      target_wx_user = WxUser.where(:wx_openid => params[:wx_openid]).first
      if target_wx_user
        ulist = target_wx_user.binded_users_list
        status = 200
        data = {data: ulist.to_json}
      else
        status = 500
        data = {message: I18n.t("wx_users.messages.warn.not_binded")}
      end
    end
    render common_json_response(status, data)
  end
end
