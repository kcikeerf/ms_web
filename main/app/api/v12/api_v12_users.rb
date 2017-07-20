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
      desc "获取用户信息"
      params do
      end
      post :get_info do
        u = current_user
        {
          :id => u.id,
          :user_name => u.name,
          :name => u.role_obj.nil? ? "-" : u.role_obj.name,
          :role => u.role.name,
          :accessable_tenants => u.accessable_tenants.map {|t| { uid: t.uid, name_cn: t.name_cn}}
        }
      end 

      desc '绑定子用户账号信息'
      params do
        requires :user_name, type: String
        requires :password, type: String
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
        requires :user_names, type: Array
      end
      post :unbind do
        if current_user
          return_code = true
          message_list = []
          users_list = params[:user_names]
          users_list.each do |u_name|
            flag,code = current_user.users_unbind u_name
            message = {user_name: u_name, code: code, message: I18n.t("api.#{code}", variable: u_name) }
            message_list << message
            return_code = return_code&&flag
          end

          if return_code
            message_list
          else
            error!(message_list, 500) 
          end
        end
      end  

    end #auths end
  end #class end
end #monitoring end