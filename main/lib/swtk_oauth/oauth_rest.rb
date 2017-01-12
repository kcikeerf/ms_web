module SwtkOauth
  module Rest #rest begin
    module_function

    def host
      result = SwtkOauth::Config::ServerInfo[:protocol] 
        + "://" 
        + SwtkOauth::Config::ServerInfo[:host] 
        + ":" 
        + SwtkOauth::Config::ServerInfo[:port]
      return result
    end

    def request api, params
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
  end # rest end
end