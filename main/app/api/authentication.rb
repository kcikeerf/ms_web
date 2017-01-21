# -*- coding: UTF-8 -*-

module Authentication
  class APIV11 < Grape::API
    version 'v1.1', using: :path #/api/v1/<resource>/<action>
    format :json
    prefix "api/".to_sym

    # Helpers
    helpers CommonHelper

    params do
    end
    resource :authenticates do #monitorings begin

      before do

      end

      ###########

      desc ''
      params do
        requires :grant_type, type: String, values: -> {["authorization_code", "password"]}
        given grant_type: ->(val){ val == "authorization_code" } do
          requires :code, type: String
          requires :redirect_uri, type: String
          requires :client_id, type: String
          requires :secret, type: String
        end
        given grant_type: ->(val){ val == "password" } do
          requires :user_name, type: String
          requires :password, type: String
        end
        optional :scope, type: String
      end
      post :token do
        case grant_type
        when "authorization_code"

        when "password"
          target_user = User.where(name: params[:user_name]).first
          if target_user && target_user.valid_password?(params[:password])
            
          end
        end
      end

      ###########

    end #auths end
  end #class end
end #monitoring end