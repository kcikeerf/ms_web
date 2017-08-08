module ApiV12SharedParamsHelper
  extend Grape::API::Helpers
  
  # params :authenticate do
  #   requires :user_name, type: String, allow_blank: false
  #   requires :wx_openid, type: String, allow_blank: false
  # end

  params :oauth do
  	requires :access_token, type: String, allow_blank: false
  end

  params :wx do
    optional :wx_openid, type: String
    optional :wx_unionid, type: String
    at_least_one_of :wx_openid, :wx_unionid
  end

  params :third do
    optional :third_party, type: String
    given third_party: ->(val) { val == 'wx' } do 
      optional :wx_openid, type: String
      optional :wx_unionid, type: String
      at_least_one_of :wx_openid, :wx_unionid
    end
  end

  params :base_info do
    optional :nickname, type: String
    optional :sex, type: Integer
    optional :province, type: String
    optional :city, type: String
    optional :country, type: String
    optional :headimgurl, type: String
  end

  params :wx_with_info do
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