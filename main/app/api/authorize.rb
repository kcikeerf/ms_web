# -*- coding: UTF-8 -*-

module Authorize
  class APIV11 < Grape::API
    version 'v1.1', using: :path #/api/v1/<resource>/<action>
    format :json
    prefix "api/".to_sym

    # 
    helpers CommonHelper

    params do
      use :authenticate
    end
    resource :authorize do #monitorings begin

      before do

      end

      ###########

      desc ''
      params do
        #
      end
      post :list do
      end

      ###########

    end #auths end
  end #class end
end #monitoring end