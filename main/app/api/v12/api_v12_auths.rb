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

      desc '获取绑定的用户列表 post /api/wx/v1.1/auths/binded_users_list'
      params do
        #
      end
      post :binded_users_list do
        current_wx_user.binded_users_list
      end

      ###########

    end #auths end
  end #class end
end #monitoring end