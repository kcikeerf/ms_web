# -*- coding: utf-8 -*-
# 

module Common

  module SwtkConstants
    file_upload_location = ""
  end

  module File

    # Upload one file 
    def single_upload params
#      if params[:str_tempid].blank?
        fu = FileUpload.new
#      else
#        fu = FileUpload.where("id = ?", params[:str_tempid]).first
#      end 
      
#      case params[:type]
#      when "question"
#        fu.paper = params[:file]
#      when "answer"
#        fu.answer = params[:file]
#      end
      fu.single = params[:file]
      fu.save!
      return fu
    end
    module_function :single_upload
 
    # Upload files 
    def multiple_upload files_h
      fu = FileUpload.new
      fu.paper = files_h[:paper]
      fu.answer = files_h[:answer]
      fu.analysis = files_h[:analysis] 
      fu.save!
      return fu
    end    
    module_function :multiple_upload

    # Get excel file content
    def get_excel_file_content file_path
      result = []
      file = nil
      case file_path.split('.').last.downcase
      when 'xlsx', 'xlsm'
        file = Roo::Excelx.new(file_path)
      when 'xls'
        file = Roo::Excel.new(file_path)
#      else:
#        file = Roo::Excelx.new(file_path)
      end
      sheet = file.sheet('试题分析') if file
      sheet.each{|row|
        result << row
      } if sheet
      return result
    end
    module_function :get_excel_file_content

    # Convert doc file content
    def get_doc_file_content_as_html file_path
      return "" if file_path.blank?
      result = ""
      location = file_path.split('/')[0..-2].join('/')
      html_name = file_path.split('/').last.split('.')[0] + '_converted.html' 

      begin
        word_cleaner_folder = Rails.root.to_s.split('/')[0..-2].join('/') + "/tools/WordCleaner7ComponentMono"
        cmd_str = "#{word_cleaner_folder}/WordCleaner7ComponentMono.exe /t '#{word_cleaner_folder}/Templates/Convert\ to\ HTML\ embed\ images.wc' /f #{file_path} /o #{location} /of #{html_name}"
        #exec cmd_str
        #if not use popen, rails app will be interrupted
        IO.popen(cmd_str){|f| f.gets}
      rescue Exception => ex
        p ex.message
      end
      arr = IO.readlines(location + '/' + html_name)
      result = arr.join('')
      return result
    end
    module_function :get_doc_file_content_as_html

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
