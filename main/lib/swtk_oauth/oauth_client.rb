module SwtkOauth
  module Client # client begin
    module_function

    API = {
      :get_access_token => {
        :method => "POST",
        :path => "/api/v1/oauth_client/get_access_token"
      },
      :verify_access_token => {
        :method => "POST",
        :path => "/api/v1/oauth_client/verify_access_token"
      }
    }

    def get_access_token
      params = {}
      SwtkOauth::Config.each{|k,v|
        params[k]=v
      }
      res = SwtkOauth::Rest.request API[:get_access_token],params
      if res && res.keys.include?("access_token")
        res["access_token"]
      else
        nil
      end
    end

    def verify_access_token access_token
      params = {:access_token => access_token}
      SwtkOauth.Config.each{|k,v|
        params[k]=v
      }
      res = SwtkOauth::Rest.request API[:verify_access_token],params
      if res && res.keys.include?("access_token")
        res["access_token"]
      else
        nil
      end
    end

  end # client end
end