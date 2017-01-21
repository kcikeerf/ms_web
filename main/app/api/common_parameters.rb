# -*- coding: UTF-8 -*-

module CommonParamsHelper
  extend Grape::API::Helpers
  
  params :authenticate do
    requires :user_name, type: String, allow_blank: false
    requires :wx_openid, type: String, allow_blank: false
  end
end