# -*- coding: UTF-8 -*-

module ApiV12WxUsers
  class API < Grape::API
    format :json

    helpers Doorkeeper::Grape::Helpers
    helpers ApiV12Helper
    helpers ApiV12SharedParamsHelper

    params do
      use :oauth
    end

    resource :wx_users do #monitorings begin

      before do
        set_api_header
        doorkeeper_authorize!
      end

      # 分组1：限制为Client认证token才可访问, begin
      group do
        before do
          not_user_token!
        end

        desc '获取绑定的用户列表'
        params do
          optional :wx_openid, type: String
          optional :wx_unionid, type: String
          at_least_one_of :wx_openid, :wx_unionid
        end
        post :binded_users_list do
          current_wx_user.binded_users_list
        end

        ###########

      end # 分组1：限制为Client认证token才可访问. end

      # 分组2: 所有有效token都可以访问, begin
      group do
        before do
          @target_wx_user = current_wx_user
        end

        desc '绑定微信用户'
        params do
          #
        end
        post :bind do
          target_user = current_user
          if @target_wx_user.binded_user?(target_user.name)
            message_json("i11201")
          else
            @target_wx_user.with_lock do
              #超过微信帐户绑定限制
              if (@target_wx_user.users.count + 1) > Common::Wx::WxBindingUserLimit
                status = 500
                message_json("w21207")
              #超过题库帐户绑定限制
              elsif (target_user.wx_users.count +1) > Common::Wx::UserBindingWxLimit
                status = 500
                message_json("w21208")
              #正确绑定
              else
                @target_wx_user.users << target_user
                message_json("i11203")
              end
            end
          end
        end

        ###########

        desc '微信解绑用户'
        params do
          #
        end
        post :unbind do
          target_user = current_user
          if @target_wx_user.binded_user?(target_user.name)
            begin
              WxUserMapping.where( :wx_uid => @target_wx_user.uid, :user_id=> target_user.id ).destroy_all
            rescue
              status 500
              message_json("i11204")
            end
          else
            message_json("i11202")
          end
        end

        ###########

        desc '完善微信用户信息'
        params do
          optional :wx_openid, type: String#, allow_blank: false
          optional :nickname, type: String
          optional :sex, type: Integer
          optional :province, type: String
          optional :city, type: String
          optional :country, type: String
          optional :headimgurl, type: String
          optional :wx_unionid, type: String
          at_least_one_of :wx_openid, :wx_unionid
        end
        post :complete_info do
          begin
            target_params = params.extract!(:wx_openid,:nickname,:sex,:province,:city,:country,:headimgurl,:wx_unionid).to_h
            @target_wx_user.update_attributes(target_params)
            status 200
            @target_wx_user.attributes
          rescue Exception => ex
            status 500
            {message: ex.message, backtrace: ex.backtrace}
          end
        end

        ###########

        desc '获取微信用户信息'
        params do
          optional :wx_openid, type: String
          optional :wx_unionid, type: String
          at_least_one_of :wx_openid, :wx_unionid
        end
        post :get_info do
          begin
            status 200
            @target_wx_user.attributes
          rescue Exception => ex
            status 500
          end
        end

        ###########
      end# 分组2: 所有有效token都可以访问, end

      # # 分组3: 公开访问
      # group do
      #   before do
      #     # nothing
      #   end

      #   desc '绑定微信用户'
      #   params do
      #     optional :wx_openid, type: String#, allow_blank: false
      #     optional :nickname, type: String
      #     optional :sex, type: Integer
      #     optional :province, type: String
      #     optional :city, type: String
      #     optional :country, type: String
      #     optional :headimgurl, type: String
      #     optional :wx_unionid, type: String
      #     at_least_one_of :wx_openid, :wx_unionid
      #   end
      #   post :bind do
      #     begin
      #       target_params = params.extract!(:wx_openid,:nickname,:sex,:province,:city,:country,:headimgurl,:wx_unionid).to_h
      #       @target_current_wx_user.update_attributes(target_params)
      #       status 200
      #       @target_current_wx_user.attributes
      #     rescue Exception => ex
      #       status 500
      #       {message: ex.message, backtrace: ex.backtrace}
      #     end
      #   end

      #   ###########
      # end# 分组2: 所有有效token都可以访问, end

    end #auths end
  end #class end
end #monitoring end