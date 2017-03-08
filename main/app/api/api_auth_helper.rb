# -*- coding: UTF-8 -*-
module ApiAuthHelper

  def white_list_domain?
    true
    # ( /http(s)?:\/\/(www.|wx.|zx.)?k12ke.com/ =~ request.referrer) ? true : false
    # request.referrer.blank?? false : !AuthWl::DomainWhiteList.where(domain: request.referrer.split(/\/$/)).blank?
  end

  def white_list_domain!
    true
    #error!(message_json("e41401"), 401) if request.referrer.blank? || AuthWl::DomainWhiteList.where(domain: request.referrer.split(/\/$/)).blank?
  end

  def set_api_header!
    header 'Access-Control-Allow-Origin','*'
    header 'Access-Control-Request-Method', 'GET, POST, PUT, HEAD'
    header 'Access-Control-Allow-Headers', 'x-requested-with,Content-Type, Authorization, Location'
    header 'Access-Control-Expose-Headers', 'Location'
  end

  def authenticate_client!
    unless white_list_domain?
      target_client = Oauth2::Client.where(_id: params[:client_id], secret: params[:secret]).first
      error!(message_json("e41401"), 401) if target_client.blank?
      target_client
    end
  end

  def authenticate_code!
    unless white_list_domain?
      target_code = Oauth2::Authorization.where(client_id: params[:client_id], redirect_uri: params[:redirect_uri], code: params[:code]).first 
      case target_code.validate_code
      when -1
        error!(message_json("e40004"), 401)
      end
      target_code 
    end
  end

  def authenticate_token!
    if white_list_domain?
      target_token = AuthWl::Token.where(access_token: params[:access_token]).first
    else
      # 第三方验证，验证access token的有效性
      target_token = Oauth2::Token.where(client_id: params[:client_id], access_token: params[:access_token]).first 
    end
    error!(message_json("e41401"), 401) if target_token.blank?
    case target_token.validate_token
    when 1
      error!(message_json("e41002"), 401)
    when -1
      error!(message_json("e40004"), 401)
    end
    target_token 
  end

  def authenticate_api_permission! user_id=nil, http_method=nil, api_path=nil
    error!(message_json("e41001"), 401) if user_id.blank?
    error!(message_json("e41401"), 401) if target_scope_h.blank?
    error!(message_json("e41401"), 401) unless Common::SwtkRedis::has_key? Common::SwtkRedis::Ns::Auth,"/users/#{user_id}/api_permissions/#{http_method}/#{api_path}" 
  end

  def authenticate_scopes! user_id=nil, target_scope_h={}
    error!(message_json("e41001"), 401) if user_id.blank?
    error!(message_json("e41401"), 401) if target_scope_h.blank?

    target_scope_h.each{|cat, cat_h|
      redis_base_key = "/users/#{user_id}/skope/#{cat}"
      cat_h.each{|rkey,rvalue|
        redis_rkey = redis_base_key + "/#{rkey}"
        user_scope_str = Common::SwtkRedis::get_value Common::SwtkRedis::Ns::Auth, redis_rkey
        error!(message_json("w21401"), 401) if user_scope_str.blank?
        user_scope_re = Regexp.new user_scope_str
        if user_scope_re.match(rvalue).blank?
          error!(message_json("w21401"), 401)
        end
      }
    }
  end

  def current_user
    # if white_list_domain?
    #   authenticate_token!
    #   target_token = authenticate_token!
    #   target_user = User.where(id: target_token.user_id).first
    #   target_user.blank?? error!(message_json("e40004"), 401) : target_user
    # else
    #   # 第三方验证，验证access token的有效性
    # end
    target_token = authenticate_token!
    target_user = User.where(id: target_token.user_id).first
    target_user.blank?? error!(message_json("e40004"), 401) : target_user
  end

  ####### 微信 ######
  # 获取登录的微信账户

  def current_wx_user
    target_wx_user = WxUser.where(:wx_openid => params[:wx_openid]).first
    unless target_wx_user
      begin
        target_wx_user = WxUser.new({:wx_openid => params[:wx_openid]})
        target_wx_user.save!
      rescue Exception => ex
        error!(message_json("e41202"), 403) unless target_wx_user
      end
    end
    return target_wx_user
  end

end
