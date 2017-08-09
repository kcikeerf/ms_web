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

  def get_3rd_user
    third_party = params[:third_party]
    _3rd_user = nil
    master_user = nil
    _3rd_user = send("current_#{third_party}_user") if third_party && Common::Uzer::ThirdPartyList.include?(third_party)
    if _3rd_user
      master_user = _3rd_user.users.by_master(true).first 
      unless  master_user
        _3rd_user.default_user!
        master_user = _3rd_user.users.by_master(true).first
      end
    end 
    return _3rd_user, master_user
  end

  # 获取登录的微信账户 
  def current_wx_user
    target_wx_user = nil
    target_wx_user1, target_wx_user2 = nil, nil
    if params[:wx_unionid]
      target_wx_user1 = WxUser.where(wx_unionid: params[:wx_unionid]).first
    end
    if params[:wx_openid]
      target_wx_user2 = WxUser.where(wx_openid: params[:wx_openid]).first
    end

    target_wx_user = target_wx_user1 || target_wx_user2
    if target_wx_user1 && target_wx_user2 &&  (target_wx_user1 != target_wx_user2)
      target_wx_user.migrate_other_wx_user_binded_user(target_wx_user2)
    end
    unless target_wx_user
      begin
        params_h = {
          :wx_unionid => params[:wx_unionid],
          :wx_openid => params[:wx_openid]
        }
        target_wx_user = WxUser.new(params_h)
        target_wx_user.default_user!
      rescue Exception => ex
        error!(message_json("e41002"), 403) unless target_wx_user
      end
    else
      target_wx_user.wx_unionid = params[:wx_unionid] if params[:wx_unionid] && target_wx_user.wx_unionid.blank?
    end
    target_wx_user.nickname = params[:nickname] if params[:nickname]
    target_wx_user.sex = params[:sex] if params[:sex]
    target_wx_user.province = params[:province] if params[:province]
    target_wx_user.city = params[:city] if params[:city]
    target_wx_user.country = params[:country] if params[:country]
    target_wx_user.headimgurl = params[:headimgurl] if params[:headimgurl]
    target_wx_user.save!
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