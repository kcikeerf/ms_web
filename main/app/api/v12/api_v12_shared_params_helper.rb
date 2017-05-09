module ApiV12SharedParamsHelper
  extend Grape::API::Helpers
  
  # params :authenticate do
  #   requires :user_name, type: String, allow_blank: false
  #   requires :wx_openid, type: String, allow_blank: false
  # end

  params :oauth do
  	requires :access_token, type: String, allow_blank: false
  end
end