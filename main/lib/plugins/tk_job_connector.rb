# -*- coding: UTF-8 -*-

require 'logger'

class TkJobConnector

  def initialize args
    @cfg = YAML.load_file("lib/plugins/tk_job_config.yml")
    @api = @cfg["tk_job"]["base_url"] + @cfg["tk_job"]["api"][args[:version]][args[:api_name]]
    @http_method = args[:http_method]
    @params = args[:params]
  end

  def logger
    Rails.logger
  end

  def execute
    result_flag = false
    uri = URI(@api)

    req = nil
    case @http_method
    when "get"
      @api += "?" + URI.encode_www_form(@params) if !@params.blank?
      req = Net::HTTP::Get.new(@api)
    when "post"
      req = Net::HTTP::Post.new(@api)
      req.body = @params.to_json
    when "delete"
      req = Net::HTTP::Delete.new(@api)
    when "patch"
      req = Net::HTTP::Patch.new(@api)
    when "put"
      req = Net::HTTP::Put.new(@api)
      req.body = @params.to_json
    end
    return false, nil unless req

    req['Accept'] = 'application/json'
    req['Content-Type'] = 'application/json'

    res = Net::HTTP.start(uri.host, uri.port, :use_ssl => false) {|http|
      http.request(req) 
    }

    case res.code
    when "200","201"
      result_flag = true
    else
      result_flag = false
    end
    return result_flag, res.body.blank?? {} : JSON.parse(res.body)
  end  
end