# -*- coding: UTF-8 -*-

require 'doorkeeper/grape/helpers'

module ApiV12Helper
  def set_api_header
    header 'Access-Control-Allow-Origin','*'
    header 'Access-Control-Request-Method', 'GET, POST, PUT, OPTIONS, HEAD'
    header 'Access-Control-Allow-Headers', 'x-requested-with,Content-Type, Authorization'    
  end

  def current_user
    target_user = User.where(id: doorkeeper_token.resource_owner_id).first if doorkeeper_token
    if params[:child_user_name]
      child_user = User.where(name: params[:child_user_name]).first
      target_user.children.include?(child_user)
      target_user = child_user
    end
    error!(message_json("e40004"), 404) unless target_user
    target_user
  end

  def not_user_token!
    error!("invalid token",400) unless doorkeeper_token.user.blank?
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
    conditions = []
    if params[:wx_openid]
      conditions << "wx_openid = '#{params[:wx_openid]}'"
    end
    if params[:wx_unionid]
      conditions << "wx_unionid = '#{params[:wx_unionid]}'"
    else
      # do nothing
    end
    target_wx_user = WxUser.where(conditions.join(" or ")).first
    unless target_wx_user
      begin
        params_h = {
          :wx_unionid => params[:wx_unionid],
          :wx_openid => params[:wx_openid]
        }
        target_wx_user = WxUser.new(option_h)
        target_wx_user.default_user!
      rescue Exception => ex
        error!(message_json("e41002"), 403) unless target_wx_user
      end
    else
      target_wx_user.update_wx_unionid(params) if params[:wx_unionid] && target_wx_user.wx_unionid.blank?
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
      message: I18n.t("api.#{code}")
    }
  end

end