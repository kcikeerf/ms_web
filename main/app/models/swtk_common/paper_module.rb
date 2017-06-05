# -*- coding: UTF-8 -*-

module PaperModule
  module Paper
    module_function

    Type = {}
    %W{
      xy_default
      zh_dyzn
      zh_fzqn
      zh_rwdy
      zh_kxjs
      zh_xhxx
      zh_jksh
      zh_zrdd
      zh_sjcx
    }.each{|item| Type[item.to_sym] = Common::Locale::i18n("dict.#{item}")}    

    QuizType = {
      #语文
      :yu_wen => {},
      #数学
      :shu_xue => {},
      #英语
      :ying_yu => {}
    }

    #语文题型
    %W{
      xuan_ze_ti
      tian_kong_ti
      lian_xian_ti
      jian_da_ti
      lun_shu_ti
      xie_zuo
    }.each{|item| QuizType[:yu_wen][item.to_sym] = Common::Locale::i18n("dict.#{item}")}

    #数学题型
    %W{
      dan_xiang_xuan_ze_ti
      tian_kong_ti
      pan_duan_ti
      ji_suan_ti
      cao_zuo_ti
      ying_yong_ti
      jie_da_ti
      tan_suo_gui_lv_ti
      tan_jiu_ti
    }.each{|item| QuizType[:shu_xue][item.to_sym] = Common::Locale::i18n("dict.#{item}")}

    #英语题型
    %W{
      ting_li_li_jie
      dan_xiang_xuan_ze
      wan_xing_tian_kong
      yue_du_li_jie
      ci_yu_yun_yong
      bu_quan_dui_hua
      shu_mian_biao_da
    }.each{|item| QuizType[:ying_yu][item.to_sym] = Common::Locale::i18n("dict.#{item}")}

    Difficulty = {
      #难度
      :rong_yi => "容易",
      :jiao_yi => "较易",
      :zhong_deng => "中等",
      :jiao_nan => "较难",
      :kun_nan => "困难"
    }

    Subject_ckp_type = 'from_subject'
    Node_ckp_type = 'from_node'

    module Constants
      OrderWidth = 5
    end

    module Status
      None = "none"
      New = "new"
      Editting = "editting"
      Editted = "editted"
      Analyzing = "analyzing" 
      Analyzed = "analyzed"
      ScoreImporting = "score_importing"
      ScoreImported = "score_imported"
      ReportGenerating = "report_generating"
      ReportCompleted = "report_completed"
    end

    RollbackStatus = {
      Status::Editting => I18n.t("papers.status.#{Status::Editting}"),
      Status::Editted => I18n.t("papers.status.#{Status::Editted}"),
      Status::Analyzing => I18n.t("papers.status.#{Status::Analyzing}")
    }

    PaperStatusList = {
      Status::None => I18n.t("papers.status.#{Status::None}"),
      Status::New => I18n.t("papers.status.#{Status::New}"),
      Status::Editting => I18n.t("papers.status.#{Status::Editting}"),
      Status::Editted => I18n.t("papers.status.#{Status::Editted}"),
      Status::Analyzing => I18n.t("papers.status.#{Status::Analyzing}"), 
      Status::Analyzed => I18n.t("papers.status.#{Status::Analyzed}"),
      Status::ScoreImporting => I18n.t("papers.status.#{Status::ScoreImporting}"),
      Status::ScoreImported => I18n.t("papers.status.#{Status::ScoreImported}"),
      Status::ReportGenerating => I18n.t("papers.status.#{Status::ReportGenerating}"),
      Status::ReportCompleted => I18n.t("papers.status.#{Status::ReportCompleted}")
    }


    def quiz_order(x,y)
      x_arr = destruct_order x
      y_arr = destruct_order y

      if x_arr[0] != y_arr[0]
        return x_arr[0] <=> y_arr[0]
      else
        return x_arr[1] <=> y_arr[1]
      end
    end

    def destruct_order orderStr
      return ["",""] if orderStr.blank?
      reg = /\(([0-9].*?)\)/
      md = reg.match(orderStr)
      quiz_order = orderStr.sub(/\(.*/,"")
      quiz_order = quiz_order.blank?? 0:quiz_order.to_i
      qizpoint_order = md.blank?? 0:md[1].to_i
      return [quiz_order,qizpoint_order]
    end
  end

  module PaperFile
    module_function

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
 
    def create_empty_result_list params
      fu = FileUpload.where(id: params[:orig_file_id]).first
      fu.empty_result = Pathname.new(params[:file_path]).open
      fu.save!
      return fu 
    end

    # Upload files 
    def multiple_upload files_h
      fu = FileUpload.new
      fu.paper = files_h[:paper]
      fu.answer = files_h[:answer]
      fu.analysis = files_h[:analysis]
      fu.save!
      return fu
    end    

    def paper_or_answer_upload(file, file_hash)      
      file.revise_paper = Pathname.new(file_hash[:revise_paper]).open unless file_hash[:revise_paper].blank?
      file.revise_answer = Pathname.new(file_hash[:revise_answer]).open unless file_hash[:revise_answer].blank?
      file.save!
      file
    end

    def generate_docx_by_html(file, html, file_name, file_column)
      doc_str = PandocRuby.html(html).to_docx
      file_path = File.join(Rails.root, "/tmp/#{file_name}.docx")
      File.open(file_path, 'wb') { |f| f.write(doc_str) }

      file = paper_or_answer_upload(file, {file_column.to_sym => file_path})
      File.delete(file_path)
      file
    end

    # Get excel file content
    def get_excel_file_content file_path
      result = []
      file = nil
      return result if file_path.blank?
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

    # Convert doc file content
    def get_doc_file_content_as_html file_path
      return "" if file_path.blank?
      result = ""
      location = file_path.split('/')[0..-2].join('/')
      html_name = file_path.split('/').last.split('.')[0] + '_converted.html' 

      begin
        word_cleaner_folder = Rails.root.to_s.split('/')[0..-2].join('/') + "/tools/WordCleaner7ComponentMono"
        #cmd_str = "mono #{word_cleaner_folder}/WordCleaner7ComponentMono.exe /t '#{word_cleaner_folder}/Templates/Convert\ to\ HTML\ embed\ images.wc' /f #{file_path} /o #{location} /of #{html_name}"
        cmd_str = "mono #{word_cleaner_folder}/WordCleaner7ComponentMono.exe /t '#{word_cleaner_folder}/Templates/swtk.wc' /f #{file_path} /o #{location} /of #{html_name}"
        #exec cmd_str
        #if not use popen, rails app will be interrupted
        p cmd_str
        IO.popen(cmd_str){|f| f.gets}
      rescue Exception => ex
        p ex.message
      end
      arr = IO.readlines(location + '/' + html_name)
      result = arr.join('')
      return result
    end

  end
end