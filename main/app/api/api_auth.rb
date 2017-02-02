# -*- coding: UTF-8 -*-
module ApiAuth
  class APIV11 < Grape::API
    version 'v1.1', using: :path #/api/v1/<resource>/<action>
    format :json
    prefix "api/".to_sym

    # Helpers
    helpers ApiCommonHelper
    helpers ApiAuthHelper

    params do
    end
    resource :auth do #monitorings begin

      before do

      end

      ###########

      desc ''
      params do
        requires :grant_type, type: String, values: -> {["authorization_code", "refresh_token"]} #,"password"]}
        given grant_type: ->(val){ val == "authorization_code" } do
          requires :code, type: String
          requires :redirect_uri, type: String
          requires :client_id, type: String
          requires :secret, type: String
        end
        # given grant_type: ->(val){ val == "password" } do
        #   requires :user_name, type: String
        #   requires :password, type: String
        # end
        given grant_type: ->(val){ val == "refresh_token" } do
          requires :user_name, type: String
          requires :refresh_token, type: String
        end
        optional :scope, type: String
      end
      post :token do
        case grant_type
        when "authorization_code"

        # when "password"
        #   target_user = User.where(name: params[:user_name]).first
        #   if target_user && target_user.valid_password?(params[:password])
        #     target_user.update_token
        #   end
        #   {
        #     "access_token": target_user.token,
        #     "token_type": "bearer",
        #     "expires_in": self.token_expired_at.strftime("%s").to_i - Time.now.strftime("%s").to_i,
        #   }
        when "refresh_token"

        end
      end

      ###########

      desc ''
      params do

      end
      post :verify_token_info do

      end

      ################################
      #       来自白名单域名的请求       #
      ################################

      group do #来自白名单域名的请求
        before do
          white_list_domain!
        end        

        desc '白名单域名请求获取access token'
        params do
          requires :user_name, type: String
          requires :password, type: String
        end
        post :user do
          target_user = User.where(name: params[:user_name]).first
          if target_user && target_user.valid_password?(params[:password])
            # 获取token对象
            target_token = AuthWl::Token.get_token_obj target_user.id

            #
            if target_token.errors.blank? 
              { 
                token_type: "Bearer",
                access_token: target_token.access_token,
                expires_in: target_token.expired_at.strftime("%s").to_i - Time.now.strftime("%s").to_i,
                refresh_token: target_token.refresh_token
              }
            else
              status 500
              message_json("e50000")
            end
            # payload = {
            #   access: target_user.authentication_token
            # }
            
            # {
            #   encrypted_data: JsonWebToken.encode(payload)
            # }
          else
            status 401
            message_json("e41001")
          end
        end

        ###########

        desc '白名单域名更新access token'
        params do
          requires :user_name, type: String
          requires :refresh_token, type: String
        end
        post :refresh_user_token do
          target_user = User.where(name: params[:user_name]).first
          if target_user
            # 获取token对象
            target_token = AuthWl::Token.where(user_id: target_user.id, refresh_token: params[:refresh_token]).first
            #
            if target_token
              target_token.save if ["1"].include?(target_token.validate_token)
              { 
                token_type: "Bearer",
                access_token: target_token.access_token,
                expires_in: target_token.expired_at.strftime("%s").to_i - Time.now.strftime("%s").to_i,
                refresh_token: target_token.refresh_token
              }
            else
              status 500
              message_json("e50000")
            end
          else
            status 401
            message_json("e41001")
          end
        end

        ###########

      end #来自k12ke域名分组

    end #auths end
  end #class end
end #monitoring end
