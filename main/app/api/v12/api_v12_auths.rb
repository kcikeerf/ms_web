# -*- coding: UTF-8 -*-

module ApiV12Auths
  class API < Grape::API
    format :json

    helpers ApiV12Helper
    helpers ApiV12SharedParamsHelper
    helpers Doorkeeper::Grape::Helpers

    params do
      use :oauth
    end

    resource :auths do #monitorings begin

      before do
        set_api_header
        doorkeeper_authorize!
      end

      ###########

      desc '获取绑定的用户列表 post /api/v1.2/auths/binded_users_list'
      params do
        optional :wx_openid, type: String#, allow_blank: false
        optional :wx_unionid, type: String
        at_least_one_of :wx_openid, :wx_unionid
      end
      post :binded_users_list do
        current_wx_user.binded_users_list
      end

      ###########

      desc '完善微信用户信息 post /api/v1.2/auths/complete_wx_user'
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
      post :complete_wx_user do
        begin
          current_wx_user.update_attributes(params)
          status 200
        rescue Exception => ex
          status 500
        end
      end

      ###########
    end #auths end
  end #class end
end #monitoring end