# -*- coding: UTF-8 -*-

require 'doorkeeper/grape/helpers'

module ApiV12Helper
  def set_api_header
    header 'Access-Control-Allow-Origin','*'
    header 'Access-Control-Request-Method', 'GET, POST, PUT, OPTIONS, HEAD'
    header 'Access-Control-Allow-Headers', 'x-requested-with,Content-Type, Authorization'    
  end

  def doorkeeper_render_error_with(error)
    case error.reason
    when :unknown
      status_code =401
      code = "e41101"
    when :expired
      status_code =403
      code = "e41100"
    when :revoked
      status_code =401
      code = "e41102"
    end
    error!(message_json(code), status_code)
  end

  def current_user
    target_user = User.where(id: doorkeeper_token.resource_owner_id).first if doorkeeper_token
    if params[:child_user_name]
      child_user = User.where(name: params[:child_user_name]).first
      target_user.children.include?(child_user)
      target_user = child_user
    end
    error!(message_json("e40004"), 404) unless target_user
    target_user.create_user_auth_redis
    target_user
  end

  def not_user_token!
    error!(I18n.t("doorkeeper.errors.messages.invalid_token.unknown"),400) unless doorkeeper_token.user.blank?
  end

  def authenticate_api_permission user_id=nil, http_method=nil, api_path=nil
    error!(message_json("e41001"), 401) if user_id.blank?
    error!(message_json("e41001"), 401) unless Common::SwtkRedis::has_key? Common::SwtkRedis::Ns::Auth,"/users/#{user_id}/api_permissions/#{http_method}#{api_path}" 
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

  def get_3rd_user(oauth2=nil)
    third_party = params[:third_party] || oauth2
    _3rd_user = nil
    master_user = nil
    _3rd_user = send("current_#{third_party}_user") if third_party && Common::Uzer::ThirdPartyList.include?(third_party)
    if _3rd_user
      master_user = _3rd_user.users.by_master(true).first 
      unless  master_user
        _3rd_user.default_user!
        master_user = _3rd_user.users.by_master(true).first
      end
      option_h = {"#{third_party}_related" => true}
      master_user.update(option_h)
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
        error!(message_json("e41100"), 403) unless target_wx_user
      end
    else
      target_wx_user.wx_unionid = params[:wx_unionid] if params[:wx_unionid] && target_wx_user.wx_unionid.blank?
      target_wx_user.wx_openid = params[:wx_openid] if params[:wx_openid]
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