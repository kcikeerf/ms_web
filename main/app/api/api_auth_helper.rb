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
    header 'Access-Control-Allow-Headers', 'x-requested-with,Content-Type, Authorization'  
  end

  def authenticate_token!
    if white_list_domain?
      target_token = AuthWl::Token.where(access_token: params[:access_token]).first
      error!(message_json("e41401"), 401) if target_token.blank?
      case target_token.validate_token
      when 1
        error!(message_json("e41002"), 401)
      when -1
        error!(message_json("e40004"), 401)
      end
      target_token
    else
      # 第三方验证，验证access token的有效性
    end
  end

  def current_user
    if white_list_domain?
      authenticate_token!
      target_token = authenticate_token!
      target_user = User.where(id: target_token.user_id).first
      target_user.blank?? error!(message_json("e40004"), 401) : target_user
    else
      # 第三方验证，验证access token的有效性
    end
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
