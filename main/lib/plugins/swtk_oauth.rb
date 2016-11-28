module SwtkOauth
  module_function

  ServerInfo = {
    :protocol => "http",
    :host => "localhost",
    :port => "3000"    
  }

  API = {
    :get_access_token => {
      :method => "POST",
      :path => "/api/v1/oauth/get_access_token"
    },
    :verify_access_token => {
      :method => "POST",
      :path => "/api/v1/oauth/verify_access_token"
    }
  }

  def host
    ServerInfo[:protocol] + "://" + ServerInfo[:host] + ":" + ServerInfo[:port]
  end

  def rest_request api, params
    uri = URI(host + api[:path])
    req = nil
    case api[:method]
    when 'GET'
      #
    when 'POST'
      req = Net::HTTP::Post.new(uri)
      req.set_form_data(params)
    end

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      return JSON.parse(res.body)
    else
      return nil
    end
  end

  def get_access_token
    params = {}
    SwtkOauthClient.Config.each{|k,v|
      params[k]=v
    }
    res = rest_request API[:get_access_token],params
    if res && res.keys.include?("access_token")
      res["access_token"]
    else
      nil
    end
  end

  def verify_access_token access_token
    params = {:access_token => access_token}
    SwtkOauthClient.Config.each{|k,v|
      params[k]=v
    }
    res = rest_request API[:verify_access_token],params
    if res && res.keys.include?("access_token")
      res["access_token"]
    else
      nil
    end
  end
end