# -*- coding: UTF-8 -*-

module ApiWxAuth
  class APIV11 < Grape::API
    version 'v1.1', using: :path #/api/v1/<resource>/<action>
    format :json
    prefix "api/wx".to_sym

    helpers ApiAuthHelper
    helpers ApiCommonHelper

    # params do
    #   use :authenticate
    # end
    resource :wx_auth do #monitorings begin

      before do
        set_api_header!
        #authenticate_token!
      end

      ###########

      desc '获取绑定的用户列表 post /api/wx/v1.1/auths/binded_users_list'
      params do
        requires :wx_openid, type: String, allow_blank: false
        requires :client_id, type: String, allow_blank: false
        requires :secret, type: String, allow_blank: false
      end
      post :wx_user do

      end      

      ###########

      desc ''
      params do
        requires :user_name, type: String, allow_blank: false
        requires :password, type: String, allow_blank: false
        requires :wx_openid, type: String, allow_blank: false
      end
      post :bind do

          target_user = User.where(name: params[:user_name]).first
          target_wx_user = WxUser.where(:wx_openid => params[:wx_openid]).first

          if target_user && target_user.valid_password?(params[:password])
            begin
              if target_wx_user
                if target_wx_user.binded_user? params[:user_name]
                  message_json("i11201")
                else
                  target_wx_user.with_lock do
                    #超过微信帐户绑定限制
                    if (target_wx_user.users.count + 1) > Common::Wx::WxBindingUserLimit
                      status 500
                      message_json("w21207", {:limit => Common::Wx::WxBindingUserLimit})
                    #超过题库帐户绑定限制
                    elsif (target_user.wx_users.count +1) > Common::Wx::UserBindingWxLimit
                      status 500
                      message_json("w21208", {:limit => Common::Wx::UserBindingWxLimit})
                    #正确绑定
                    else
                      target_wx_user.users << target_user
                      message_json("i11203")
                    end
                  end
                end
              else
                current_wx_user = WxUser.new({
                  :wx_openid => params[:wx_openid],
                  :users => [target_user]
                })
                current_wx_user.save!
                message_json("i11203")
              end
            rescue Exception => ex
              status 500
              message_json("e50000")
            end
          else
            status 401
            message_json("e41001")
          end

      end

      ###########

      desc ''
      params do
        requires :user_name, type: String, allow_blank: false
        requires :wx_openid, type: String, allow_blank: false
      end
      post :unbind do

        target_user = User.where(name: params[:user_name]).first
        target_wx_user = WxUser.where(:wx_openid => params[:wx_openid]).first
        
        begin
          if target_wx_user && target_user
            if target_wx_user.binded_user? params[:user_name]
              WxUserMapping.where(:wx_uid =>target_wx_user.uid, :user_id=>target_user.id).destroy_all
              message_json("i11204")
            else
              message_json("i11202")
            end
          else
            raise
          end
        rescue Exception => ex
          status 500
          message_json("e50000")
        end

      end

      ###########

      desc '获取绑定的用户列表 post /api/wx/v1.1/auths/binded_users_list'
      params do
        requires :wx_openid, type: String, allow_blank: false
      end
      post :binded_users_list do
        current_wx_user.binded_users_list
      end

      ###########

      desc ''
      params do
        requires :user_name, type: String, allow_blank: false
        requires :wx_openid, type: String, allow_blank: false
      end
      post :check_bind do
        target_user = User.where(name: params[:user_name]).first
        target_wx_user = WxUser.where(:wx_openid => params[:wx_openid]).first
        if target_user && target_user.role_obj && target_wx_user && (target_wx_user.binded_user? target_user.name)
          message_json("i11201")
        else
          message_json("w21201")
        end
      end

      ###########

    end #auths end
  end #class end
end #monitoring end