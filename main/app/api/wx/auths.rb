# -*- coding: UTF-8 -*-

module Auths
  class API < Grape::API
    version 'v1.1', using: :path #/api/v1/<resource>/<action>
    format :json
    prefix "api/wx".to_sym

    helpers ApiHelper
    helpers SharedParamsHelper

    params do
      #use :authenticate
    end
    resource :auths do #monitorings begin

      before do
        set_api_header
        # authenticate!
      end

      ###########

      desc '获取绑定的用户列表 get /api/wx/v1.1/auths/binded_users_list'
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