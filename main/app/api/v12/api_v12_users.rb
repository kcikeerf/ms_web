# -*- coding: UTF-8 -*-

module ApiV12Users
  class API < Grape::API
    format :json

    helpers Doorkeeper::Grape::Helpers
    helpers ApiV12Helper
    helpers ApiV12SharedParamsHelper

    params do
      use :oauth
    end

    resource :users do #monitorings begin

      before do
        set_api_header
        doorkeeper_authorize!
      end

      desc '单个回退'
      params do
        use :third
        use :base_info      
      end
      post :rollback_wechat do
        if doorkeeper_token.user.blank?
          current_3rd_user, master_user = get_3rd_user
          error!(message_json("e41008"),401) unless master_user
        else
          master_user = current_user
        end
        begin
          if master_user
            master_user.children = []
            master_user.wx_related = false
            master_user.save!
            master_user.wx_users.delete(master_user.wx_users.first)
            message_json("i00000")
          else
            error!(message_json("i00001"),500)
          end
        rescue Exception => e
          error!(message_json("i00001").merge({error: e.message}),500)
        end

      end

      desc "按时间回退"
      params do
        use :third
        requires :roll_time, type: String
      end
      post :rollback_wechat_with_time do
        roll_time = Time.parse(params[:roll_time])
        wx_users = WxUser.where("dt_update > ?", roll_time )
        begin       
          wx_users.each do |wx|
            if wx.master
              master_user = wx.master
              master_user.children = []
              master_user.wx_related = false
              master.save!
              master.wx_users.delete(master_user)
            end
          end
          message_json("i00000")
        rescue Exception => e
          error!(message_json("i00001"),500)
        end
      end

      desc "获取绑定的账号列表"
      params do
        use :third
        use :base_info
      end
      post :get_binded_users do
        if doorkeeper_token.user.blank?
          current_3rd_user, master_user = get_3rd_user
          error!(message_json("e41008"),401) unless master_user
        else
          master_user = current_user
        end
        if master_user && master_user.is_master
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
        optional :user_nickname, type: String
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
        if user
          if user.is_customer
            find_user = User.where(name: params[:user_name])
            if find_user
              error!(message_json("w21009"), 500)
            else
              user.update(name: params[:user_name], password: params[:password], nickname: params[:user_nickname], is_customer: false)  if params[:user_name] && params[:password]
            end
          else
            user.update(nickname: params[:user_nickname])
          end
          target_3rd_user = nil            
          target_3rd_user, master_user = get_3rd_user
          if target_3rd_user
            target_3rd_user = current_wx_user
            target_params = params.extract!(:nickname,:sex,:province,:city,:country, :headimgurl, :wx_unionid, :wx_openid).to_h
            target_3rd_user.update_attributes(target_params)
          end
          user.get_user_base_info
        else
          error!(message_json("e41001"), 500)
        end
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
        master_user = nil
        cond1 = Common::Uzer::ThirdPartyList.include?(params[:target_user_from]) && params[:target_user_from].present?
        cond2 = Common::Uzer::ThirdPartyList.include?(params[:current_platform]) && params[:current_platform].present?
        case_value = params[:target_user_from] if cond1
        case_value = params[:current_platform] if !cond1 && cond2
        target_3rd_user, master_user = get_3rd_user(case_value) if case_value
 #       send("current_#{case_value}_user") if case_value
 
        if _user.is_master
          if target_3rd_user
           
            case_value_cn = I18n.t("oauth2.#{case_value}")
            #当有target_user 为三方绑定一个主账号
            if target_user && target_user.valid_password?(params[:password])
              if target_user.is_master 
                if _user.is_customer && !target_user.send("#{case_value}_related?")       
                  code, status = _user.associate_master(target_3rd_user, target_user, case_value)
                else
                  code, status = "w21007", 500
                  message = {code: code, message: I18n.t("api.#{code}", oauth2: case_value_cn)}
                end
              else
                code, status = "w21006", 500
              end
            #没有target_user 为从Pc端绑定三方的账号
            else
              if params[:user_name]
                code, status = "e41010", 500
              else
                if master_user 
                  if master_user.is_customer
                    code, status = _user.associate_master(target_3rd_user, _user, case_value)
                  else
                    code, status = "w21008", 500
                    message = {code: code, message: I18n.t("api.#{code}", oauth2: case_value_cn)}
                  end
                else
                  code, status = "w20000", 504
                end
              end
            end

            target_params = params.extract!(:nickname,:sex,:province,:city,:country, :headimgurl).to_h
            target_3rd_user.update_attributes(target_params)
          else
            #没有第三方账号时默认为绑定身份账号
            if target_user && target_user.valid_password?(params[:password])
              if target_user.is_master              
                code, status = "e41006", 500
              else
                code, status = _user.slave_user(target_user) # model
              end
            else
              code, status = "e41011", 500
            end  
          end
        else
          code, status = "w21004", 500
        end
        if [200,201].include?(status)
          result = message_json(code)
          if target_3rd_user.present?
            fresh_master = target_3rd_user.users.by_master(:true).first
          else
            fresh_master = _user
          end
          result[:oauth] = _user.fresh_access_token
          result
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