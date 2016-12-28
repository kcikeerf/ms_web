# -*- coding: UTF-8 -*-

module ApiHelper
  def set_api_header
    header 'Access-Control-Allow-Origin','*'
    header 'Access-Control-Request-Method', 'GET, POST, PUT, OPTIONS, HEAD'
    header 'Access-Control-Allow-Headers', 'x-requested-with,Content-Type, Authorization'    
  end

  def authenticate!
    error!(message_json("e41001"), 401) unless current_user
  end

  def current_user
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

  def current_tenant
    tenant = nil
    if current_user.is_project_administrator?
      tenant = nil
    else
      tenant = current_user.role_obj.tenant
    end
    tenant
  end

  # 获取登录的微信账户 
  def current_wx_user
    target_wx_user = WxUser.where(:wx_openid => params[:wx_openid]).first
    unless target_wx_user
      begin
        target_wx_user = WxUser.new({:wx_openid => params[:wx_openid]})
        target_wx_user.save!
      rescue Exception => ex
        error!(message_json("e41002"), 403) unless target_wx_user
      end
    end
    return target_wx_user
  end

  def get_online_test_user_link
    Mongodb::OnlineTestUserLink.where({
      online_test_id: params[:online_test_id],
      wx_user_id: current_wx_user.id
    }).first
  end

  def message_json code
    {
      code: code,
      message: I18n.t("api.wx.#{code}")
    }
  end
end