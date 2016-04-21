module Common

  module Response

    # Analyze the params to check callback type
    def get_callback_type params
      params[:callback].blank? ? "3,,no" : ((params[:callback]=='window.name')? "1,,#{params[:callback]}" : "2,,#{params[:callback]}")
    end
    module_function :get_callback_type

    # Used for format the response data if have callback parameter    
    def format_response_json json_target,callback_type
      arr = callback_type.split(',,')
      data_str = ""

      case json_target.class.to_s
      when 'Hash','Array'#Array maybe no this type
        data_str = json_target.to_json
      when 'String'
        data_str = json_target
      end 

      case arr[0].to_i
      #如果request中带有callback参数，并且callback等于"window.name"
      when 1
        '<script type="text" id="json">
           {"data":' + data_str + '}
        </script>
        <script type="text/javascript">window.name=document.getElementById("json").innerHTML;</script>'
      #如果request中带有callback参数，并且callback不等于"window.name"（例如是"xui.SAjax.No._1"）
      when 2
        arr[1] + '({"data":' + data_str + '}});'
      #如果request中没有callback
      when 3
        '{"data":' + data_str  + '}'
      end
    end
    module_function :format_response_json

    # Used to change the bson id name to normal id name
    def exchange_record_id bson_id
      bson_id.gsub!(/(\"_id\":{\"\$oid\":)(\"[0-9a-z]{1,}\")(})/) do |m|      # do not know why the $2 cannot work
        '"id":' + m.scan(/(\"[0-9a-z]{1,}\")/)[0][0]
      end
      return bson_id
    end
    module_function :exchange_record_id

  end
 
end
