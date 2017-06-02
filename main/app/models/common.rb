# -*- coding: utf-8 -*-
# 

module Common
  include LocaleModule
  include SwtkConstantsModule
  include RegionModule
  include CheckpointCkpModule
  include GradeModule
  include KlassModule
  include NodeVersionModule
  include PaperModule
  include PageModule
  include ReportModule
  include Report2Module
  include ReportPlusModule
  include ReportPlus2Module
  include RoleModule
  include ScoreModule
  include SubjectModule
  include SwtkRedisModule
  include TaskJobModule
  include TenantModule
  include TermModule
  include TestModule
  include UzerModule
  include WcModule
  include WxModule
  include Mongodb

  module_function

  def logger
    Rails.logger
  end

  def method_template_with_rescue(from_where, &block)
    logger.info(">>>>>>#{from_where}: begin<<<<<<<")
    begin
      yield
    rescue Exception => ex
      logger.debug ">>>Exception!<<<"
      logger.debug ex.message
      logger.debug ex.backtrace
    ensure
      logger.info(">>>>>>#{from_where}: end<<<<<<<")
    end
  end

  def method_template_log_only(from_where, &block)
    logger.debug(">>>>>>#{from_where}: begin<<<<<<<")
    yield
    logger.debug(">>>>>>#{from_where}: end<<<<<<<")
  end

  def process_sync_template(from_where, &block)
    logger.debug(">>>>>>#{from_where}: begin<<<<<<<")
    pids = []
    yield(pids)
    pids.each{|pid| Process.waitpid(pid)}
    logger.debug(">>>>>>#{from_where}: end<<<<<<<")
  end

  def valid_json?(str)
    return false if str.blank?
    begin
      JSON.parse(str)
      return true
    rescue JSON::ParserError => e
      return false
    end
  end

  def insert_item_to_arr_with_order type, target_arr, arr
    keys = target_arr.map{|a| a[0]}
    last_key = ""
    keys.each{|key|
      case type
      when "quiz"
        if Common::Paper::quiz_order(arr[0], key) < 0
          last_key = key
          break
        end
      when "klass"
        if Common::Locale.mysort(Common::Klass::Order[arr[0]],Common::Klass::Order[key]) < 0
          last_key = key
          break
        end
      when "project", "grade", "pupil"
        if compare_eng_num_str(arr[0], key) < 0
          last_key = key
          break
        end
      when "checkpoint"
        if Common::CheckpointCkp::compare_rid(arr[0], key) < 0
          last_key = key
          break
        end
      when "dimesion"
        if Common::Locale.mysort(arr[0],key) < 0
          last_key = key
          break
        end
      end
    }
    target_arr.insert_before(last_key, arr)
    return target_arr
  end

  def compare_eng_num_str(x,y)
    result = 0
    x = x || ""
    y = y || ""
    length = (x.length < y.length) ? x.length : y.length

    0.upto(length-1) do |i|
      if x[i] == y[i]
        next
      else
        if x[i] =~ /[0-9a-z]/
          if y[i] =~ /[0-9a-z]/
            result = x[i] <=> y[i]
            break
          else
            result = 1
            break
          end
        elsif y[i] =~ /[0-9a-z]/
          result = -1
          break
        else
          result = x[i] <=> y[i]
          break
        end
      end
    end
    if result == 0
      return (x.length > y.length)? 1:-1
    else
      return result
    end
  end

  module Image
    module_function
    def file_upload(user, file, crop)
      fu = user.image_upload || user.build_image_upload
      fu.crop_x = crop["x"]
      fu.crop_y = crop["y"]
      fu.crop_w = crop["width"]
      fu.crop_h = crop["height"]
      fu.crop_r = crop["rotate"]
      fu.file = file
      fu.save
      return fu 
    end
  end

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
