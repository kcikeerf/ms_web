# -*- coding: UTF-8 -*-

module ApiV12Users
  class API < Grape::API
    format :json

    helpers ApiV12Helper
    helpers ApiV12SharedParamsHelper
    helpers Doorkeeper::Grape::Helpers

    params do
      use :oauth
    end

    resource :users do #monitorings begin

      before do
        set_api_header
        doorkeeper_authorize!
      end

      desc "获取绑定的账号列表"
      params do
      end
      post :get_binded_users do
        if current_user
          current_user.binded_users_list
        end
      end 


      desc '绑定子用户账号信息'
      params do
        optional :user_name, type: String
        optional :password, type: String
      end
      post :bind do
        if current_user
          flag,code = current_user.users_bind params
          if flag
            message_json(code)
          else
            error!(message_json(code), 500) 
          end
        else
          error!(message_json("e41002"), 500) 
        end
      end

      desc '解绑子用户账号信息'
      params do
        optional :user_name, type: String
      end
      post :unbind do
        if current_user
          flag,code = current_user.users_unbind params
          if flag
            message_json(code)
          else
            error!(message_json(code), 500)
          end
        end
      end  

    end #auths end
  end #class end
end #monitoring end