# -*- coding: UTF-8 -*-

module ApiHelper
  def wx_set_api_header
    headers['Access-Control-Allow-Origin'] = 'wx.k12ke.com'
    headers['Access-Control-Request-Method'] = 'GET, POST, PUT, OPTIONS, HEAD'
    headers['Access-Control-Allow-Headers'] = 'x-requested-with,Content-Type, Authorization'    
  end

  def wx_authenticate!
    error!(message_json("e40001"), 401) unless wx_current_user
  end

  def wx_current_user
    params.permit!
    result = nil

    target_user = User.where(name: params[:user_name]).first
    return target_user
    target_wx_user = WxUser.where(:wx_openid => params[:wx_openid]).first
    if target_wx_user && target_user
      if target_wx_user.binded_user? target_user.name
        result = target_user
      end
    end
    return result
  end

  def wx_current_tenant
    tenant = nil
    if current_user.is_project_administrator?
      tenant = nil
    elsif current_user.is_pupil?
      tenant = current_user.role_obj.location.tenant
    else
      tenant = current_user.role_obj.tenant
    end
    tenant
  end

  def message_json code
    {
      code: code,
      message: I18n.t("api.v1_1.#{code}")
    }
  end
end