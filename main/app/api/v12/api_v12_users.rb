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
        use :third
        use :base_info
      end
      post :get_binded_users do
        if doorkeeper_token.user.blank?
          current_3rd_user, master_user = get_3rd_user
        else
          master_user = current_user
        end
        if master_user.is_master
          master_user.binded_users_list
        else
          error!(message_json("w21004"),500)
        end
      end 
      desc "获取用户信息"
      params do
      end
      post :get_info do
        u = current_user
        current_user ? u.get_user_base_info : {}
      end 

      desc "完善账号信息"
      params do
        optional :user_name, type: String
        optional :password, type: String
        optional :third_party, type: String
        given third_party: ->(val) { val == 'wx' } do 
          optional :wx_openid, type: String
          optional :wx_unionid, type: String
          optional :nickname, type: String
          optional :sex, type: Integer
          optional :province, type: String
          optional :city, type: String
          optional :country, type: String
          optional :headimgurl, type: String
          at_least_one_of :wx_openid, :wx_unionid
        end
      end
      post :complete_info do
        user = current_user
        if user && user.is_customer
          user.update(name: params[:user_name], password: params[:password], is_customer: false)  if params[:user_name] && params[:password]
        end
        result = []
        if params[:third_party] == "wx"
          target_params = params.extract!(:nickname,:sex,:province,:city,:country, :headimgurl, :wx_unionid, :wx_openid).to_h
          current_wx_user.update_attributes(target_params)
          result =  current_wx_user.attributes
        end
        result
      end

      desc '绑定子用户账号信息或关联主账号（三方）'
      params do
        optional :target_user_from
        given target_user_from: -> (val){ val == "zx"} do
          requires :user_name
          requires :password
        end
        given target_user_from: -> (val){ val == "wx"} do
          use :wx_with_info
        end        

        optional :current_platform
        given current_platform: -> (val){ val == "pc"} do
          # optional :wx_openid, type: String
          # optional :wx_unionid, type: String
          # at_least_one_of :wx_openid, :wx_unionid
          
        end        
        given current_platform: -> (val){ val == "wx"} do
          use :wx_with_info
        end
        # given current_platform: -> (val){ val == "qq"} do
        #   optional :wx_openid, type: String
        #   optional :wx_unionid, type: String
        #   at_least_one_of :wx_openid, :wx_unionid 
        # end
        at_least_one_of :target_user_from, :current_platform 
      end
      post :bind do

        _user = current_user  #access token
        target_user = User.where(name: params[:user_name]).first if params[:user_name].present?
        
        case_value = nil
        target_3rd_user = nil
        cond1 = Common::Uzer::ThirdPartyList.include?(params[:target_user_from]) && params[:target_user_from].present?
        cond2 = Common::Uzer::ThirdPartyList.include?(params[:current_platform]) && params[:current_platform].present?
        case_value = params[:target_user_from] if cond1
        case_value = params[:current_platform] if !cond1 && cond2
        target_3rd_user = send("current_#{case_value}_user") if case_value
 
        if _user.is_master
          if target_3rd_user
            
            if _user.send("#{case_value}_related?") or target_user.send("#{case_value}_related?")
              code, status = "w21007", 500
              case_value_cn = I18n.t("oauth2.#{case_value}")
              message = {code: code, message: I18n.t("api.#{code}", oauth2: case_value_cn)}
            else
              #当有target_user 为三方绑定一个主账号
              if target_user && target_user.valid_password?(params[:password])
                if target_user.is_master              
                  code, status = _user.associate_master(target_3rd_user, target_user, case_value)
                else
                  code, status = "w21006", 500
                end
              #没有target_user 为从Pc端绑定三方的账号
              else
                code, status = _user.associate_master(target_3rd_user, _user, case_value)
              end
            end
          else
            #没有第三方账号时默认为绑定身份账号
            if target_user && target_user.valid_password?(params[:password])
              if target_user.is_master              
                code, status = "e41006", 500
              else
                code, status = _user.slave_user(target_user) # model
              end
            end  
          end
        else
          code, status = "w21004", 500
        end
        if [200,201].include?(status)
          message_json(code)
        else
          error!(message_json(code), status) unless message
          error!(message, status) if message
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